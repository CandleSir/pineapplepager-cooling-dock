#!/usr/bin/env python3
"""Geometry tests for the Pager cooling dock.

Drives the openscad CLI (2021.01, CGAL). Usage:
    python3 -I tests/check.py [substring-filter ...]

Interference primitive: is_empty("intersection(){A(); B();}") renders the
expression and reports whether the result has no geometry. The Hak5
reference STL is not a closed mesh, so CGAL cannot boolean it; dock tests
use pager_envelope(), and test_envelope_contains_ref proves (in Python)
that the envelope contains every vertex of the reference mesh.
"""
import json
import math
import re
import struct
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIB = REPO / "src" / "lib.scad"
REF_STL = REPO / "hak5-wifi-pineapple-pager.stl"
VARIANTS = [80, 92, 120]
V2 = [(60, 15), (60, 25), (40, 10), (40, 20)]


def vd(v):
    return {"fan_size": v[0], "fan_t": v[1]}


def tag(v):
    return "%dx%d" % v
BED = 256.0


class ScadError(Exception):
    pass


def _defines(defines):
    args = []
    for k, v in (defines or {}).items():
        if isinstance(v, str):
            v = '"%s"' % v
        elif isinstance(v, bool):
            v = "true" if v else "false"
        args += ["-D", "%s=%s" % (k, v)]
    return args


def run_scad(expr, defines=None, timeout=900, out="stl"):
    """Render `expr` (with src/lib.scad included). Returns (log, out_path)."""
    tmp = Path(tempfile.mkdtemp(prefix="dockt-"))
    src = tmp / "t.scad"
    src.write_text("include <%s>\n%s\n" % (LIB, expr))
    dst = tmp / ("t." + out)
    cmd = ["openscad", "-o", str(dst)] + _defines(defines) + [str(src)]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    log = p.stdout + p.stderr
    warns = [l for l in log.splitlines() if "WARNING" in l
             and "top level object is empty" not in l and "No top level geometry" not in l]
    if "ERROR" in log or "Assertion" in log or warns:
        raise ScadError(log[-3000:])
    if p.returncode != 0 and "top level object is empty" not in log \
            and "No top level geometry" not in log:
        raise ScadError(log[-3000:])
    return log, dst


def echo_json(expr, defines=None):
    """Run `expr`, which must echo(str("J ", value)); return parsed values."""
    log, _ = run_scad(expr + "\ncube(0.01);", defines, out="csg")
    vals = []
    for m in re.finditer(r'ECHO: "J (.*)"', log):
        vals.append(json.loads(m.group(1).replace("undef", "null")))
    if not vals:
        raise ScadError("no J echo in:\n" + log[-2000:])
    return vals


def P(name, defines=None):
    """Value of a top-level variable/expression from lib.scad."""
    return echo_json('echo(str("J ", %s));' % name, defines)[0]


def stl_facets(path):
    data = Path(path).read_bytes()
    if data[:5] == b"solid" and b"facet" in data[:400]:
        tris, cur = [], []
        for line in data.decode().splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                cur.append(tuple(float(x) for x in line.split()[1:4]))
                if len(cur) == 3:
                    tris.append(tuple(cur))
                    cur = []
        return tris
    n = struct.unpack("<I", data[80:84])[0]
    tris = []
    for i in range(n):
        d = struct.unpack("<12f", data[84 + 50 * i: 84 + 50 * i + 48])
        tris.append((d[3:6], d[6:9], d[9:12]))
    return tris


def stl_bbox(path):
    pts = [v for t in stl_facets(path) for v in t]
    if not pts:
        return None
    return ([min(p[k] for p in pts) for k in range(3)],
            [max(p[k] for p in pts) for k in range(3)])


def is_empty(expr, defines=None, timeout=1800):
    log, dst = run_scad(expr, defines, timeout=timeout)
    if "top level object is empty" in log or "No top level geometry" in log:
        return True
    return not dst.exists() or len(stl_facets(dst)) == 0


# ---------------------------------------------------------------- tests
TESTS = []


def test(fn):
    TESTS.append(fn)
    return fn


def approx(a, b, tol):
    assert abs(a - b) <= tol, "%r != %r (tol %r)" % (a, b, tol)


@test
def test_pager_params_match_stl():
    lo, hi = stl_bbox(REF_STL)
    L, W, T, clip_t, btn_h = P("[pg_L, pg_W, pg_T, pg_clip_t, pg_btn_h]")
    approx(hi[0] - lo[0], L, 0.3)
    approx(hi[1] - lo[1], W + pg_side_btn_proud(), 0.3)
    approx(hi[2] - lo[2], T + clip_t + btn_h, 0.3)


def pg_side_btn_proud():
    return P("pg_side_btn[1][1] - pg_W/2")


@test
def test_envelope_contains_ref():
    """Every reference-mesh vertex lies inside pager_envelope(clip=true)."""
    boxes, (L, W, T, r, zc), g = P(
        "[pg_env_boxes, [pg_L, pg_W, pg_T, pg_r, pg_zc], env_grow]")
    pts = {v for t in stl_facets(REF_STL) for v in t}
    zb, zf = zc - T / 2, zc + T / 2
    outside = []
    for x, y, z in pts:
        if zb - g <= z <= zf + g:
            ax, ay = abs(x) - (L / 2 - r), abs(y) - (W / 2 - r)
            if (ax <= 0 or ay <= 0) and abs(x) <= L / 2 + g and abs(y) <= W / 2 + g:
                continue
            if ax > 0 and ay > 0 and math.hypot(ax, ay) <= r + g:
                continue
        if any(b[0][0] - g <= x <= b[1][0] + g and b[0][1] - g <= y <= b[1][1] + g
               and b[0][2] - g <= z <= b[1][2] + g for b in boxes):
            continue
        outside.append((x, y, z))
    assert not outside, "%d vertices outside envelope, e.g. %s" % (
        len(outside), outside[:5])


@test
def test_pose_on_slope():
    n, lo_edge, hi_edge, minz, lip_z, ang = P(
        "[pose_dir([0,0,1]), pose_pt([0,-pg_W/2,pg_zc]), pose_pt([0,pg_W/2,pg_zc]),"
        " min([for (p = pg_env_corners(true)) pose_pt(p)[2]]), lip_z, seat_angle]")
    approx(ang, 45, 0)
    approx(n[0], 0, 1e-6)
    approx(n[1], -math.sin(math.radians(45)), 1e-6)
    approx(n[2], math.cos(math.radians(45)), 1e-6)
    assert lo_edge[2] < hi_edge[2], "-Y edge must be the lower edge"
    assert lo_edge[1] < hi_edge[1], "-Y edge must be nearest the user"
    assert minz >= lip_z - 1e-6, "posed pager dips below lip_z: %r" % minz


# ---------------------------------------------------------------- task 2
def per_variant(fn_body):
    for fs in VARIANTS:
        fn_body(fs)


@test
def test_fits_bed():
    def one(fs):
        _, dst = run_scad("dock();", {"fan_size": fs})
        lo, hi = stl_bbox(dst)
        size = [hi[k] - lo[k] for k in range(3)]
        assert all(s <= BED for s in size), "%d: %r exceeds bed" % (fs, size)
    per_variant(one)


@test
def test_trapezoid_profile():
    def one(fs):
        H, D, Wd = P("[H, D, Wd]", {"fan_size": fs})
        _, dst = run_scad("dock();", {"fan_size": fs})
        lo, hi = stl_bbox(dst)
        approx(hi[2], H, 0.5)
        approx(lo[2], 0, 0.01)
        approx(hi[1] - lo[1], D, 0.5)
        approx(hi[0] - lo[0], Wd, 0.5)
    per_variant(one)


FAN_POSES = {
    "as-is": "fan_pose() fan_envelope();",
    # turned over (rotate 180 about the fan's Y axis) and turned 90 in-plane
    "flipped": "fan_pose() translate([0,0,fan_t]) rotate([0,180,0]) fan_envelope();",
    "rot90": "fan_pose() rotate([0,0,90]) fan_envelope();",
    "flip-rot270": "fan_pose() translate([0,0,fan_t]) rotate([0,180,0]) rotate([0,0,270]) fan_envelope();",
}


@test
def test_fan_fits_both_thickness():
    for fs in VARIANTS:
        for t in (25, 15):
            assert is_empty("intersection(){dock(); %s}" % FAN_POSES["as-is"],
                            {"fan_size": fs, "fan_t": t}), "%d/%d interferes" % (fs, t)


@test
def test_fan_fits_flipped():
    for fs in VARIANTS:
        for name, pose in FAN_POSES.items():
            assert is_empty("intersection(){dock(); %s}" % pose, {"fan_size": fs}), \
                "%d %s interferes" % (fs, name)


@test
def test_fan_retained():
    for fs in VARIANTS:
        d = {"fan_size": fs}
        # sliding 2 mm down the rear slope is blocked by the tray's lower wall
        assert not is_empty("intersection(){dock(); translate(-2*rear_t()) fan_pose() fan_envelope();}", d), \
            "%d: fan can slide out of the tray" % fs
        # lifting straight out along the rear-face normal is unobstructed
        # stepped sweep (hull() of the non-convex fan+bump would invent material)
        assert is_empty("intersection(){dock(); for (i = [0:5:60])"
                        " translate(i*rear_n()) fan_pose() fan_envelope(); }", d), \
            "%d: drop-in path obstructed" % fs


@test
def test_fan_sits_on_ledge():
    for fs in VARIANTS:
        # pushed 0.5 mm further in, the fan must hit the inner ledge (it can't fall into the plenum)
        assert not is_empty("intersection(){dock(); translate(-0.8*rear_n()) fan_pose() fan_envelope();}",
                            {"fan_size": fs}), "%d: fan not supported by ledge" % fs


# ---------------------------------------------------------------- task 3
def each_variant_clip(fn):
    for fs in VARIANTS:
        for clip in ("true", "false"):
            fn({"fan_size": fs}, clip)


@test
def test_seat_clip_on_clear():
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); pager_pose() pager_envelope(true);}",
                        {"fan_size": fs}), "%d: clip-on pager interferes" % fs


@test
def test_seat_clip_off_clear():
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); pager_pose() pager_envelope(false);}",
                        {"fan_size": fs}), "%d: clip-off pager interferes" % fs


@test
def test_seat_supported():
    """Pushed 0.8 mm further into the seat, the pager must hit the floor (it rests, not floats)."""
    def one(d, clip):
        g = P("seat_clear - env_grow", d)
        assert not is_empty(
            "intersection(){dock(); translate(-%f*slope_n()) pager_pose() pager_envelope(%s, btns=false);}"
            % (g + 0.8, clip), d), "%r clip=%s floats" % (d, clip)
    each_variant_clip(one)


@test
def test_drop_in_path():
    """Lifting the seated pager 40 mm straight out of the face is unobstructed."""
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); for (i = [0:4:40])"
                        " translate(i*slope_n()) pager_pose() pager_envelope(true);}",
                        {"fan_size": fs}), "%d: drop-in path obstructed" % fs


def plug_boxes():
    # 20 (along Y) x 15 (along Z) x 25 (out along X) "fat plug" per USB port, STL frame
    ports = P("port_centres")
    return " ".join(
        "translate([port_end_sign*(pg_L/2 + 0.5 + 12.5), %f, %f]) cube([25, 20, 15], center=true);"
        % (y, z) for y, z in ports)


@test
def test_ports_exposed():
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); pager_pose() { %s }}" % plug_boxes(),
                        {"fan_size": fs}), "%d: plug blocked" % fs


@test
def test_pinch_access():
    """A 12 x 20 x 16 mm finger pocket beyond each short end, at mid-thickness and above, is clear."""
    for fs in VARIANTS:
        assert is_empty(
            "intersection(){dock(); pager_pose() for (sx = [-1, 1])"
            " translate([sx*(pg_L/2 + 0.5 + 6), 0, pg_zc + 4]) cube([12, 20, 16], center=true);}",
            {"fan_size": fs}), "%d: no pinch access" % fs


# ---------------------------------------------------------------- task 4
ROOM_AIR = ["seat_pocket", "end_windows", "exhaust_chamber", "button_notch",
            "fan_cable_channel", "pager_cable_guide"]


@test
def test_exhaust_isolated():
    """Every room-air cut stays >= wall-0.4 away from the plenum (only the intake duct joins them)."""
    for fs in VARIANTS:
        for m in ROOM_AIR:
            assert is_empty("intersection(){plenum(); %s(g = wall - 0.4);}" % m, {"fan_size": fs}), \
                "%d: %s leaks into the plenum" % (fs, m)


@test
def test_plenum_reaches_fan():
    """Just inside the tray floor, the whole fan opening is plenum."""
    for fs in VARIANTS:
        probe = ("fan_pose() translate([0, 0, -wall - fan_clear - 3]) linear_extrude(2)"
                 " square(fan_size - 2*fan_ledge - 8, center = true);")
        assert is_empty("difference(){ %s plenum(); }" % probe, {"fan_size": fs}), \
            "%d: plenum doesn't reach the fan opening" % fs


@test
def test_intake_covers_vents():
    for fs in VARIANTS:
        for i in (0, 1):
            zone = ("pager_pose() let(v = vent_lo[%d]) translate([v[0], -pg_W/2 - 1.5, v[2]])"
                    " cube([v[1] - v[0], 1.5, v[3] - v[2]]);" % i)
            assert is_empty("difference(){ %s intake_duct(); }" % zone, {"fan_size": fs}), \
                "%d: vent %d not covered by the intake duct" % (fs, i)


@test
def test_intake_joins_plenum():
    for fs in VARIANTS:
        d = {"fan_size": fs}
        _, dst = run_scad("intersection(){ intake_duct(); plenum(); }", d)
        bb = stl_bbox(dst) if dst.exists() else None
        assert bb, "%d: intake duct never reaches the plenum" % fs
        v = P("vent_lo", d)
        assert bb[0][0] <= v[0][0] and bb[1][0] >= v[1][1], \
            "%d: duct/plenum overlap %r doesn't span both grilles" % (fs, bb)


@test
def test_exhaust_covers_vent():
    for fs in VARIANTS:
        zone = ("pager_pose() let(v = vent_hi) translate([v[0], pg_W/2, v[2]])"
                " cube([v[1] - v[0], 1.5, v[3] - v[2]]);")
        assert is_empty("difference(){ %s exhaust_chamber(); }" % zone, {"fan_size": fs}), \
            "%d: upper grille not open to the exhaust" % fs


@test
def test_bar_grille_open_area():
    bar, gap = P("[grille_bar, grille_gap]")
    assert gap / (bar + gap) >= 0.70, "grille open area %.2f" % (gap / (bar + gap))
    for fs in VARIANTS:
        assert not is_empty("intersection(){dock(); bar_grille();}", {"fan_size": fs}), \
            "%d: grille bars missing from the dock" % fs


@test
def test_button_notch_clear():
    for fs in VARIANTS:
        assert is_empty(
            "intersection(){dock(); pager_pose() translate([(btn_hi[0] + btn_hi[1])/2,"
            " pg_W/2 + seat_clear + 8.2, (btn_hi[2] + btn_hi[3])/2]) cylinder(d = 16, h = 60);}",
            {"fan_size": fs}), "%d: side button not reachable" % fs


def _normal(t):
    a, b, c = t
    u = [b[i] - a[i] for i in range(3)]
    v = [c[i] - a[i] for i in range(3)]
    n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
    ln = math.sqrt(sum(x * x for x in n)) or 1.0
    return [x / ln for x in n], ln / 2


def bridges(tris, tol=0.02):
    """Spans the slicer must bridge (printed standing on z = 0): returns
    (hanging, ceilings). hanging = lengths of horizontal edges that are the lowest
    line of every face meeting them, collinear pieces merged; ceilings = the
    narrower plan extent of each flat down-facing face group, by height."""
    def key(p):
        return tuple(round(c, 3) for c in p)
    edges, flat = {}, {}
    for t in tris:
        n, area = _normal(t)
        for i in range(3):
            a, b, o = t[i], t[(i + 1) % 3], t[(i + 2) % 3]
            edges.setdefault(frozenset((key(a), key(b))), []).append((n, o))
        z = min(p[2] for p in t)
        if n[2] < -0.99 and z > 0.05 and area > 1e-6:
            lo, hi = flat.setdefault(round(z, 1), ([1e9, 1e9], [-1e9, -1e9]))
            for p in t:
                for k in (0, 1):
                    lo[k], hi[k] = min(lo[k], p[k]), max(hi[k], p[k])
    runs = {}
    for e, fs in edges.items():
        if len(e) != 2 or len(fs) != 2:
            continue
        a, b = sorted(e)
        if abs(a[2] - b[2]) > tol or a[2] < 0.05:
            continue
        if all(n[2] <= 0.01 and o[2] > a[2] + tol for n, o in fs):
            d = [b[i] - a[i] for i in range(3)]
            ln = math.sqrt(sum(x * x for x in d))
            u = tuple(round(abs(x) / ln, 2) for x in d)
            # line id: direction + position across it (all runs here are along X or Y)
            line = (u, round(a[2], 1), round(a[1] if u[0] > 0.5 else a[0], 1))
            ax = 0 if u[0] > 0.5 else 1
            runs.setdefault(line, []).append(sorted((a[ax], b[ax])))
    hanging = []
    for segs in runs.values():
        segs.sort()
        cur = list(segs[0])
        for s0, s1 in segs[1:]:
            if s0 <= cur[1] + tol:
                cur[1] = max(cur[1], s1)
            else:
                hanging.append(cur[1] - cur[0])
                cur = [s0, s1]
        hanging.append(cur[1] - cur[0])
    ceilings = {z: min(hi[0] - lo[0], hi[1] - lo[1]) for z, (lo, hi) in flat.items()}
    return hanging, ceilings


@test
def test_no_long_bridges():
    """Supports stay OFF (the plenum is closed), so nothing may hang: every edge with
    nothing beneath it and every flat ceiling spans at most bridge_max."""
    for fs in VARIANTS:
        d = {"fan_size": fs}
        _, dst = run_scad("dock();", d)
        hanging, ceilings = bridges(stl_facets(dst))
        lim = P("bridge_max", d) + 0.1
        assert max(hanging) <= lim, "%d: hanging edges %s mm" % (
            fs, [round(x, 1) for x in sorted(hanging, reverse=True)[:4]])
        wide = {z: round(w, 1) for z, w in ceilings.items() if w > lim}
        assert not wide, "%d: flat ceilings wider than bridge_max at z=%s" % (fs, wide)


@test
def test_gasket_groove_cut():
    """Groove is cut, with >= 1.2 mm of wall below it (over the duct) and >= 1.0 mm above (to the face)."""
    for fs in VARIANTS:
        d = {"fan_size": fs}
        assert is_empty("intersection(){dock(); gasket_groove();}", d), "%d: groove not cut" % fs
        # probes stop 0.01 short of the groove faces (coincident faces leave CGAL slivers)
        for dz, h in ((-1.2, 1.19), (groove_w_val(d) + 0.01, 0.99)):
            probe = ("pager_pose() translate([-pg_L/2 + pg_r, -pg_W/2 - seat_clear - groove_d,"
                     " groove_z + %f]) cube([pg_L - 2*pg_r, groove_d, %f]);" % (dz, h))
            assert is_empty("difference(){ %s dock(); }" % probe, d), \
                "%d: groove wall at dz=%s thinner than %s mm" % (fs, dz, h)


def groove_w_val(d):
    return P("groove_w", d)


# ---------------------------------------------------------------- task 5
@test
def test_cable_channel_open_top():
    """The fan cable drops in from outside along the whole channel: a slightly narrower
    probe from the channel floor out along the rear-face normal hits nothing."""
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); fan_cable_channel(probe = true);}", {"fan_size": fs}), \
            "%d: fan cable channel closed somewhere" % fs


@test
def test_cable_channel_reaches_tray_and_edge():
    for fs in VARIANTS:
        d = {"fan_size": fs}
        _, dst = run_scad("fan_cable_channel();", d)
        lo, hi = stl_bbox(dst)
        Dv, tray_lo_z = P("[D, (fan_v0) * sin(seat_angle)]", d)
        assert hi[1] >= Dv - 0.01 and lo[2] <= 0.01, "%d: channel doesn't exit at the rear-bottom edge" % fs
        assert hi[2] >= tray_lo_z, "%d: channel doesn't reach the tray" % fs


@test
def test_adapter_pocket():
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); adapter_probe();}", {"fan_size": fs}), \
            "%d: no room for a 15x10x30 inline adapter" % fs
        # the pocket runs out through the rear-bottom edge (no thin sliver left at the edge)
        assert is_empty("intersection(){dock(); rear_frame() translate([adapter_at[0] - adapter[0]/2 + 0.2,"
                        " -2, -adapter[2] + 0.2]) cube([adapter[0] - 0.4, 4, 40]);}", {"fan_size": fs}), \
            "%d: sliver of wall left below the adapter pocket" % fs


@test
def test_pager_cable_guide_open():
    for fs in VARIANTS:
        assert is_empty("intersection(){dock(); pager_cable_guide(probe = true);}", {"fan_size": fs}), \
            "%d: pager cable guide closed" % fs


@test
def test_coupon_small():
    for fs in VARIANTS:
        d = {"fan_size": fs}
        _, dst = run_scad("coupon();", d)
        bb = stl_bbox(dst)
        assert bb, "%d: coupon empty" % fs
        lo, hi = bb
        size = [hi[k] - lo[k] for k in range(3)]
        cap = P("seat_depth + seat_clear + wall", d)
        assert all(x <= BED for x in size), size
        approx(lo[2], 0, 0.01)
        assert size[2] <= cap + 0.5, "%d: coupon %r taller than the seat cradle" % (fs, size)


@test
def test_gasket_fits_groove():
    d = {"fan_size": 92}
    _, dst = run_scad("gasket();", d)
    assert stl_bbox(dst), "gasket empty"
    assert is_empty("intersection(){dock(); gasket_seated();}", d), "gasket collides with the dock"
    assert not is_empty("intersection(){pager_pose() pager_envelope(); gasket_seated();}", d), \
        "gasket doesn't reach the pager (no seal)"


# ---------------------------------------------------------------- final review fixes
@test
def test_fan_slot_isolated():
    """The fan tray keeps >= wall-0.4 from every seat-area cut (no plenum bypass)."""
    for fs in VARIANTS:
        for m in ["seat_pocket", "exhaust_chamber", "button_notch", "end_windows"]:
            assert is_empty("intersection(){fan_slot(); %s(g = wall - 0.4);}" % m, {"fan_size": fs}), \
                "%d: fan tray breaks into %s" % (fs, m)


@test
def test_plenum_sealed():
    """Plug the fan tray and the intake duct: exactly one enclosed void (the plenum) remains."""
    for fs in VARIANTS:
        log, _ = run_scad(
            "union(){ dock(); intake_duct(); fan_pose() translate([-fan_size/2 - 6, -fan_size/2 - 6,"
            " -fan_clear - 0.01]) cube([fan_size + 12, fan_size + 12, 200]); }", {"fan_size": fs})
        vols = re.findall(r"Volumes:\s+(\d+)", log)
        assert vols and int(vols[-1]) == 3, "%d: plugged dock has %s volumes (3 = sealed)" % (fs, vols[-1:])


@test
def test_optional_grill_fits():
    """A screw-on Noctua grill (fan-sized, 2.5 mm incl. screw heads) fits on the outer face,
    or on the inner face with the fan riding 2.5 mm higher in the tray."""
    for fs in VARIANTS:
        d = {"fan_size": fs}
        grill = "cube([fan_size, fan_size, 2.5], center = false)"
        outer = ("fan_pose() { fan_envelope(); translate([-fan_size/2, -fan_size/2, fan_t]) %s; }" % grill)
        inner = ("translate(2.5*rear_n()) fan_pose() { fan_envelope();"
                 " translate([-fan_size/2, -fan_size/2, -2.5]) %s; }" % grill)
        for name, e in (("outer", outer), ("inner", inner)):
            assert is_empty("intersection(){dock(); %s}" % e, d), "%d: grill on %s face interferes" % (fs, name)


# ---------------------------------------------------------------- coupon round 1: top-wall play
def stl_volume(path):
    return abs(sum(
        (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
         + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0 for a, b, c in stl_facets(path)))


@test
def test_top_wall_clearance():
    """Pocket's +Y wall sits seat_clear_top off the pager; the -Y (seal) wall stays at seat_clear.
    Probes at mid-thickness: +Y between the exhaust and the button notch, -Y beyond the ducts."""
    d = {"fan_size": 92}
    g, ct, c = P("[env_grow, seat_clear_top, seat_clear]")
    assert g < ct < c, "need env_grow < seat_clear_top < seat_clear, got %r" % ([g, ct, c],)
    hit ="pg_W/2 + seat_clear_top + 0.05", "pg_W/2 + seat_clear_top + 0.3"
    assert not is_empty("intersection(){dock(); pager_pose() translate([-12, %s, pg_zc - 2])"
                        " cube([10, %s - (%s), 4]);}" % (hit[0], hit[1], hit[0]), d), \
        "+Y wall is not seat_clear_top from the pager"
    assert is_empty("intersection(){dock(); pager_pose() translate([-12, pg_W/2, pg_zc - 2])"
                    " cube([10, seat_clear_top - 0.05, 4]);}", d), "+Y wall closer than seat_clear_top"
    assert not is_empty("intersection(){dock(); pager_pose() translate([30, -pg_W/2 - seat_clear - 0.3,"
                        " pg_zc - 2]) cube([4, 0.25, 4]);}", d), "-Y wall moved out"
    assert is_empty("intersection(){dock(); pager_pose() translate([30, -pg_W/2 - seat_clear + 0.05,"
                    " pg_zc - 2]) cube([4, seat_clear - 0.05, 4]);}", d), "-Y wall moved in"


@test
def test_fit_gauge():
    """The gauge collar is the dock pocket's outline: the pager passes, its walls sit at the
    pocket's clearances, and it costs a fraction of the coupon's filament."""
    _, g = run_scad("fit_gauge();")
    bb = stl_bbox(g)
    assert bb, "gauge empty"
    approx(bb[0][2], 0, 0.01)
    approx(bb[1][2], P("gauge_h"), 0.01)
    mid = "translate([0, 0, gauge_h/2 - pg_zc])"
    assert is_empty("intersection(){fit_gauge(); %s pager_envelope(true);}" % mid), "pager doesn't pass"
    for y0, y1, side in (("pg_W/2 + seat_clear_top + 0.05", "pg_W/2 + seat_clear_top + 0.3", "+Y"),
                         ("-pg_W/2 - seat_clear - 0.3", "-pg_W/2 - seat_clear - 0.05", "-Y")):
        assert not is_empty("intersection(){fit_gauge(); translate([30, %s, 0]) cube([4, %s - (%s), 1]);}"
                            % (y0, y1, y0)), "%s wall not at the pocket clearance" % side
    _, c = run_scad("coupon();", {"fan_size": 80})
    assert stl_volume(g) < 0.2 * stl_volume(c), "gauge %.1f cm3 vs coupon %.1f cm3" % (
        stl_volume(g) / 1000, stl_volume(c) / 1000)


# ---------------------------------------------------------------- v0.2 task 1: tilted fan frame
@test
def test_fan_faces_back_tilted():
    n, u, t = P("[fan_n(), fan_u(), fan_tilt]")
    approx(t, 15, 0)
    a = math.radians(15)
    for got, want in ((n, [0, math.cos(a), math.sin(a)]), (u, [0, -math.sin(a), math.cos(a)])):
        for k in range(3):
            approx(got[k], want[k], 1e-6)


@test
def test_fan_clear_of_seat_cuts():
    """The slot's inner face plane sits >= wall + 0.5 behind every seat-cut corner along fan_n."""
    for v in V2:
        pn, ext, w = P("[fan_origin() * fan_n(), seat_ext(), wall]", vd(v))
        assert pn - ext >= w + 0.5 - 1e-6, "%s: %.2f behind seat cuts" % (tag(v), pn - ext)


@test
def test_hole_under_slab():
    """The hole's top (+1 mm), on the chamber side of the land, is >= 1 mm behind the seat slab."""
    for v in V2:
        d, sd = P("[(fan_origin() + (hole_r + 1)*fan_u() - wall*fan_n()) * [0, sin(seat_angle), -cos(seat_angle)],"
                  " slab_d]", vd(v))
        assert d >= sd + 1 - 1e-6, "%s: hole top only %.2f behind the face" % (tag(v), d)


@test
def test_housing_on_desk():
    for v in V2:
        zs = P("[for (k = housing_corners()) k[2]]", vd(v))
        approx(min(zs), 0, 1e-6)


# ---------------------------------------------------------------- runner
def main(argv):
    flt = argv[1:]
    sel = [t for t in TESTS if not flt or any(f in t.__name__ for f in flt)]
    failed = 0
    for t in sel:
        t0 = time.time()
        try:
            t()
            print("PASS %-40s %6.1fs" % (t.__name__, time.time() - t0), flush=True)
        except Exception as e:  # noqa: BLE001 - report every failure
            failed += 1
            msg = str(e).strip().splitlines()
            print("FAIL %-40s %6.1fs  %s: %s" % (
                t.__name__, time.time() - t0, type(e).__name__,
                " | ".join(msg[-4:])[:600]), flush=True)
    print("%d passed, %d failed" % (len(sel) - failed, failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
