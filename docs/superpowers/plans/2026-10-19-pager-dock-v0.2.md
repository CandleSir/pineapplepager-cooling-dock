# Pager Dock v0.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the dock's back end for small 5 V Noctua fans: a tapered body with an upright, tilted, drop-in fan slot, a small chamber that runs straight from the fan to the Pager's intake, and a snap-together MERV 8 filter frame. Four variants: 60×15, 60×25, 40×10, 40×20.

**Architecture:**
- The seat geometry (`pager.scad` and the seat cuts in `body.scad`) is unchanged.
- `fan.scad` gains a tilted fan frame, and the fan's position is computed from two constraints:
  - the slot stays clear of every seat cut;
  - the air hole stays under the seat slab.
- `body.scad`:
  - the body is `hull(seat_block, fan_housing, its floor shadow)`;
  - the slot, lips, cable reliefs and teardrop hole are cut in the fan's local frame;
  - `chamber()` replaces `plenum()`, as an intersection of half-spaces.
- New parts: `filter.scad` (grid frame and cap frame) and a fan-slot gauge.

**Tech Stack:** OpenSCAD 2021.01 (CGAL, slow), Python 3 stdlib test harness (`tests/check.py`), GNU make, git-lfs.

**Spec:** `docs/superpowers/specs/2026-10-19-pager-dock-v0.2-design.md` (builds on `2026-10-18-pager-cooling-dock-design.md`)

## Global Constraints

- **Printing:**
  - Bambu P1S: every part fits in 256 × 256 × 256 mm.
  - PLA Matte, 0.4 mm nozzle, walls ≥ 2 mm (`wall = 2.4`).
  - **Supports OFF.** No hanging edge or flat ceiling longer than `bridge_max = 25` (enforced by `test_no_long_bridges`).
- **Seat frozen.** Do not change seat parameters (`seat_angle`, `seat_u0`, `seat_depth`, `seat_clear`, `seat_clear_top`, `env_grow`, all `pg_*`, vents, ports, buttons). Do not change the seat modules either: `pocket_plan`, `seat_pocket`, `end_windows`, `intake_duct`, `exhaust_chamber`, `bar_grille`, `button_notch`, `gasket_groove`, `pager_cable_guide`, `fit_gauge`, `gasket*`.
- **Variants** are exactly 60×15, 60×25, 40×10 and 40×20, selected by `-D fan_size=… -D fan_t=…`. The 80/92/120 variants are removed (the v0.1.0 tag keeps them).
- **Fan mounting:**
  - The fan faces straight back, tilted `fan_tilt = 15`°, with its top leaning toward the front.
  - The slot is open at the top, and the fan is held by gravity.
  - The teardrop air hole stays inside the fan frame. No ribs.
  - `fan_clear = 0.3` per side.
- **Chamber:** shrink it with half-spaces only; never add solid fill inside the air path. Solid body outside the chamber is printed as sparse infill. The README must tell the user to drop infill (Printing section).
- **Filter:** two snap-together frames (grid on the fan side, cap on the room side) with MERV 8 media between them. The filter is left out in pull mode.
- **Git:**
  - Work on branch `v0.2` off `main`.
  - Never add `Co-Authored-By` or any AI attribution.
  - `*.stl` and `*.png` are already LFS-tracked.
- **Test harness:** the harness fails on any OpenSCAD WARNING. Run it with `python3 -I tests/check.py [substring …]`.

## Review Focus

1. **The cable can exit at either lower corner, along the bottom edge or the side edge, and the fan can be flipped.** All four fan poses must fit every variant. Covered by Task 2, `test_fan_fits`.
2. **No air path bypasses the filter or the land through the open slot top.** The hole must stay inside the fan frame (Task 2, `test_hole_inside_land`), and the slot must stay sealed from the chamber except through the hole (Task 3, `test_slot_isolated_from_chamber`).
3. **The tilted slot channel must not cut into the seat cuts on any variant.** The button notch is the tightest spot. Covered by Task 2, `test_fan_slot_isolated`.
4. **The chamber must print with supports off and stay sealed.** Covered by Task 3, `test_no_long_bridges` and `test_chamber_sealed`.
5. **Pull mode or no filter:** with the frames snapped together empty as a spacer, the fan can't walk off its land. Covered by Task 4, `test_spacer_slack`.

## Planning calls (Claude's, for the user to check)

1. **Fan position:** set by the button notch. Leaning 15° forward, a slot that's open at the top has to stay clear of the side-button finger notch above the Pager's top edge. That puts the fan's inner face about 116–119 mm behind the front edge, and makes the dock about 140–150 mm deep, down from 228.
2. **Fan cable:** it leaves the slot's lower corner straight out the back at desk level. The new back has no room for v0.1's cable channel or the 30 × 15 × 10 mm adapter pocket, so the adapter lies on the desk behind the dock.
3. **"Hollow" means slicer infill:** a modeled sealed void under the shallow tapered top would need supports inside it, so the solid body outside the chamber is printed as sparse infill instead. The README carries the infill note (≈10 %).
4. **Chamber shape:** two 45° ceilings, the seat slab's underside and a cap sloping down onto the top of the hole. The floor is level, 1 mm under the lowest of the hole and the intake duct. Every surface prints without supports.
5. **Spacer:** with no media, both frames snap together empty. The fan then has 0.6 mm more slack (`filter_gap`) than with media; `test_spacer_slack` bounds it.
6. **Fan gauges:** two, one for the 40 and one for the 60. Each is built with the thicker fan's depth (20 / 25 mm), because the gauge tests the width fit and how the fan seats, not the depth.

---

## File map

| File | Change |
|---|---|
| `src/params.scad` | Fan block rewritten. Old v0.1 rear-slope params removed. Filter params added. |
| `src/fan.scad` | Rewritten: tilted frame, `fan_origin()`, envelope with bottom-corner cable bump. |
| `src/body.scad` | New `seat_block`, `fan_housing_local`, `body_shell`, `slot_local`, `hole2d`, `fan_slot`, `chamber`, `below`, `fan_gauge`. Removed: `fan_slot` (old), `plenum`, `rear_frame`, `cable_path`, `fan_cable_channel`, `adapter_*`. |
| `src/filter.scad` | New: `filter_grid()`, `filter_cap()`. |
| `src/lib.scad` | Also includes `filter.scad`. |
| `src/dock.scad` | Parts: `dock`, `coupon`, `gasket`, `gauge`, `fan-gauge`, `filter-grid`, `filter-cap`. |
| `tests/check.py` | `VARIANTS` becomes `(size, t)` tuples. v0.1 fan, plenum and cable tests are replaced. |
| `Makefile`, `README.md`, `tools/preview.scad`, `stl/`, `previews/` | New variant names. Old outputs removed. |

Shared test helpers (Task 1 adds them):

```python
VARIANTS = [(60, 15), (60, 25), (40, 10), (40, 20)]
def vd(v): return {"fan_size": v[0], "fan_t": v[1]}
def tag(v): return "%dx%d" % v
```

---

### Task 1: Tilted fan frame and placement

**Files:**
- Modify: `src/params.scad` (fan section), `src/fan.scad` (rewrite), `tests/check.py`
- Create: none

**Interfaces:**
- Consumes: `pose_pt`, `box_corners`, `slope_n()`, `slope_t()`, and the seat params from `pager.scad` / `params.scad`.
- Produces:
  - **Params:**
    - `fan_size = 60`, `fan_t = 25`, `fan_tilt = 15`
    - `fan_clear = 0.3`, `fan_clear_z = 0.5`, `fan_ledge = 3`, `fan_lip = 3`, `fan_nub = [8, 4, 6]`
    - `frame_t = 1.6`, `filter_gap = 0.6`, `filter_border = 4`, `grid_bar = 1.2`, `grid_pitch = 8`, `peg_d = 2`, `peg_fit = 0.2`
    - derived: `filter_stack = 2*frame_t + filter_gap`, `slot_depth = fan_t + filter_stack + fan_clear_z`, `hole_r = fan_size/2 - fan_ledge`, `relief = fan_clear + fan_nub[1] + 0.5`, `hx = fan_size/2 + relief + wall`, `slab_d = seat_depth + seat_clear + wall`
  - **Functions and modules:**
    - `fan_n()`: `[0, cos(fan_tilt), sin(fan_tilt)]`, out of the slot (back and up).
    - `fan_u()`: `[0, -sin(fan_tilt), cos(fan_tilt)]`, up the fan plane.
    - `seat_cut_boxes()`: pager-frame boxes `[[min],[max]]` for the pocket, exhaust, button notch and clip relief + wall.
    - `seat_ext()`: the largest `pose_pt(k) * fan_n()` over every corner of `seat_cut_boxes()`.
    - `fan_origin()`: dock-frame centre of the fan's inner face.
    - `fan_pt(p)`: fan-local to dock frame.
    - `fan_pose()`: children in the fan frame (x = X, y = `fan_u`, z = `fan_n`).
    - `fan_envelope(t = fan_t)`: frame plus a cable bump on the −y edge near the +x corner.
    - `housing_corners()`: the 8 dock-frame corners of the housing box.

- [ ] **Step 0: Branch**

```bash
git checkout -b v0.2 main
```

- [ ] **Step 1: Write the failing tests** (append to `tests/check.py`; add the helpers above near `VARIANTS`, keeping the old `VARIANTS` until Task 2)

```python
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
```

`V2` is the new variant list, kept separate from the old `VARIANTS` until Task 2 replaces it: `V2 = [(60, 15), (60, 25), (40, 10), (40, 20)]`.

- [ ] **Step 2: Run them and watch them fail**

Run: `python3 -I tests/check.py test_fan_faces test_fan_clear_of test_hole_under test_housing_on`
Expected: all 4 FAIL with ScadError (unknown function/variable `fan_n` etc. → WARNING).

- [ ] **Step 3: Implement**
  - **`params.scad`:**
    - Replace the fan block with the params listed under Produces.
    - Delete `fan_hole`, `fan_tray`, `fan_v0`, `H_fan`, `H_pager`, `run`, `top_flat`, `D_min`, `D`, `ch_w`, `ch_d` and `adapter`.
    - Set `H = seat_u_top * sin(seat_angle)` and `Wd = pg_L + 2*seat_clear + 2*wall + 2*side_margin`.
    - Keep `seat_u_top`, `guide_*` and `bridge_max`.
    - Delete `rib_w` only if nothing still uses it (Task 3 keeps the clip posts, which use it, so keep it).
  - **`fan.scad`:** rewrite with the functions listed under Produces. Delete `rear_t()` and `rear_n()`. Use these formulas (`a = seat_angle`, `t = fan_tilt`):

```openscad
function slab_in() = [0, sin(seat_angle), -cos(seat_angle)];
function fan_z0() = hx * cos(fan_tilt) + wall * sin(fan_tilt);        // housing's lowest corner on z = 0
function fan_y_clear(z) = (seat_ext() + wall + 0.5 - z * sin(fan_tilt)) / cos(fan_tilt);
function fan_y_hole(z) = (slab_d + 1 + z * cos(seat_angle)
                          - (hole_r + 1) * (fan_u() * slab_in()) + wall * (fan_n() * slab_in())) / sin(seat_angle);
function fan_origin() = let(z = fan_z0()) [0, max(fan_y_clear(z), fan_y_hole(z)), z];
```

The housing box in fan-local coordinates is `[[-hx, -hx, -wall], [hx, fan_size/2 + fan_clear, slot_depth + wall]]`. Its lowest corner is `(y = -hx, z = -wall)`, which is what `fan_z0()` puts on z = 0.

`seat_cut_boxes()` (pager frame; `c = seat_clear`, `back = pg_zc - pg_T/2`):
- pocket: `[[-pg_L/2 - c, -pg_W/2 - c, back - c], [pg_L/2 + c, pg_W/2 + seat_clear_top, face_z]]`
- exhaust: `[[vent_hi[0] - vent_margin, pg_W/2 - 1, back - c], [vent_hi[1] + vent_margin, pg_W/2 + c + exh_w, face_z]]`
- notch: `[[cx - notch_w/2, pg_W/2 - 1, btn_hi[2] - 3], [cx + notch_w/2, pg_W/2 + c + notch_len, face_z]]`, where `cx = (btn_hi[0] + btn_hi[1])/2`
- clip relief + wall: `pg_clip_box` grown by `clip_relief + wall` on every side

`fan_envelope(t)`: `cube` of `fan_size × fan_size × t` centred in x/y on z ∈ [0, t], plus the bump `translate([fan_size/2 - 6 - fan_nub[0], -fan_size/2 - fan_nub[1] + 0.01, (t - fan_nub[2])/2]) cube([fan_nub[0], fan_nub[1], min(fan_nub[2], t)])`.

`fan_pose()`: `multmatrix` with columns `[1,0,0]`, `fan_u()`, `fan_n()` and translation `fan_origin()`. `fan_pt(p)` applies the same matrix to a point.

`body.scad` still references the deleted names, so `dock()` will not render until Task 2. Only run Task 1's tests in this task.

- [ ] **Step 4: Run the tests and watch them pass**

Run: `python3 -I tests/check.py test_fan_faces test_fan_clear_of test_hole_under test_housing_on`
Expected: 4 passed. Also echo `fan_origin()` for each variant. Expected y is about 116 (60) or 119 (40); if it's far off, recheck `seat_cut_boxes()`.

- [ ] **Step 5: Commit**

```bash
git add src/params.scad src/fan.scad tests/check.py
git commit -m "feat(v0.2): tilted fan frame placed behind the seat cuts"
```

---

### Task 2: Tapered body and drop-in fan slot

**Files:**
- Modify: `src/body.scad`, `src/dock.scad` (unchanged parts list for now), `tests/check.py`

**Interfaces:**
- Consumes: everything Task 1 produces.
- Produces:
  - `seat_block()`: the 45° slab parallelogram `[[0,0],[slab_d/sin a,0],[(slab_d + H cos a)/sin a, H],[H cos a/sin a, H]]` in YZ, extruded `Wd` across X (same `rotate([90,0,90]) linear_extrude(…, center=true)` idiom as v0.1's `body_shell`).
  - `fan_housing_local()`: the housing box from Task 1.
  - `body_shell()`: `hull(){ seat_block(); fan_pose() fan_housing_local(); linear_extrude(0.01) projection() fan_pose() fan_housing_local(); }`. The last term gives the housing a flat base.
  - `hole2d()`: a teardrop of radius `hole_r` (hull of a circle and a point at `hole_r*sqrt(2)`), cut off at y = `hole_r`.
  - `slot_local(g = 0, hole = true)`, fan-local cuts, every one grown by `g` except the hole:
    - **slot:** x ±(`fan_size/2 + fan_clear`), y from −(`fan_size/2 + fan_clear`) to +200, z from 0 to `slot_depth`;
    - **rear window:** x ±(`fan_size/2 - fan_lip`), y from −(`fan_size/2 - fan_lip`) to +200, z from `slot_depth - 0.01` to +100;
    - **corner reliefs, both sides:** x from `fan_size/2 - 6 - fan_nub[0] - 1` to `fan_size/2 + relief`, y from −(`fan_size/2 + relief`) to −(`fan_size/2 - 6 - fan_nub[0] - 1`), z from 0 to +100;
    - **hole** (if `hole`): `translate([0,0,-wall-1]) linear_extrude(wall + 1.01) hole2d()`.
  - `fan_slot(g = 0, hole = true)`: `fan_pose() slot_local(g, hole)`.
  - `dock()`: `difference(){ body_shell(); fan_slot(); seat_pocket(); end_windows(); intake_duct(); exhaust_chamber(); button_notch(); gasket_groove(); pager_cable_guide(); }` plus `bar_grille()`. `chamber()` arrives in Task 3.
  - Removed: old `fan_slot`, `plenum`, `rear_frame`, `cable_path`, `adapter_at`, `fan_cable_channel`, `adapter_probe`.

- [ ] **Step 1: Write the failing tests.**
  - Replace `VARIANTS = [80, 92, 120]` with `VARIANTS = V2`.
  - Make every existing test that loops `for fs in VARIANTS` use `d = vd(v)`, keeping its assertions.
  - Delete these v0.1 tests: `test_trapezoid_profile`, `test_fan_fits_both_thickness`, `test_fan_fits_flipped`, `test_fan_retained`, `test_fan_sits_on_ledge`, `test_plenum_reaches_fan`, `test_intake_joins_plenum`, `test_plenum_sealed`, `test_fan_slot_isolated`, `test_optional_grill_fits`, `test_cable_channel_open_top`, `test_cable_channel_reaches_tray_and_edge`, `test_adapter_pocket`, `test_exhaust_isolated`, `test_coupon_small`, `test_gasket_fits_groove`. Task 3 and Task 4 bring back the last five in their new form.
  - Add:

```python
STACK = "translate([-fan_size/2, -fan_size/2, fan_t]) cube([fan_size, fan_size, filter_stack]);"
FAN_POSES = {  # cable bump: bottom edge right / left, side edge left / right
    "down-right": "fan_envelope();",
    "down-left": "translate([0,0,fan_t]) rotate([0,180,0]) fan_envelope();",
    "side-left": "rotate([0,0,-90]) fan_envelope();",
    "side-right": "translate([0,0,fan_t]) rotate([0,180,0]) rotate([0,0,-90]) fan_envelope();",
}


@test
def test_profile():
    for v in VARIANTS:
        d = vd(v)
        H, Wd, hx, top = P("[H, Wd, hx, fan_pt([0, fan_size/2 + fan_clear, slot_depth + wall])[2]]", d)
        _, dst = run_scad("dock();", d)
        lo, hi = stl_bbox(dst)
        assert all(hi[k] - lo[k] <= BED for k in range(3)), tag(v)
        approx(lo[2], 0, 0.01)
        approx(hi[2], H, 0.5)
        approx(hi[0] - lo[0], Wd, 0.5)
        assert 2 * hx < Wd and top < H, "%s: back doesn't taper (hx %.1f, top %.1f)" % (tag(v), hx, top)


@test
def test_fan_fits():
    for v in VARIANTS:
        for name, pose in FAN_POSES.items():
            assert is_empty("intersection(){dock(); fan_pose() { %s %s }}" % (pose, STACK), vd(v)), \
                "%s %s interferes" % (tag(v), name)


@test
def test_fan_seats_on_land():
    for v in VARIANTS:
        assert not is_empty("intersection(){dock(); translate(-0.3*fan_n()) fan_pose() fan_envelope();}", vd(v)), \
            "%s: nothing stops the fan at the land" % tag(v)


@test
def test_fan_drop_in():
    for v in VARIANTS:
        assert is_empty("intersection(){dock(); for (i = [0:5:120]) translate(i*fan_u())"
                        " fan_pose() { fan_envelope(); %s }}" % STACK, vd(v)), "%s: drop-in blocked" % tag(v)


@test
def test_stack_retained():
    for v in VARIANTS:
        assert not is_empty("intersection(){dock(); translate((fan_clear_z + 0.3)*fan_n()) fan_pose() { %s }}"
                            % STACK, vd(v)), "%s: lips don't hold the filter stack" % tag(v)


@test
def test_slot_clearance():
    fc = P("fan_clear")
    approx(fc, 0.3, 1e-9)
    for v in VARIANTS:
        d = vd(v)
        assert not is_empty("intersection(){dock(); fan_pose() translate([fan_size/2 + fan_clear + 0.05, -5, 2])"
                            " cube([0.25, 10, 4]);}", d), "%s: side wall not at fan_clear" % tag(v)
        assert is_empty("intersection(){dock(); fan_pose() translate([fan_size/2, -5, 2])"
                        " cube([fan_clear - 0.05, 10, 4]);}", d), "%s: side wall inside fan_clear" % tag(v)


@test
def test_hole_inside_land():
    for v in VARIANTS:
        assert is_empty("difference(){ fan_pose() translate([0,0,-wall-1]) linear_extrude(wall + 1.01) hole2d();"
                        " fan_pose() translate([-(fan_size/2 - 1), -(fan_size/2 - 1), -50])"
                        " cube([fan_size - 2, fan_size - 2, 100]); }", vd(v)), "%s: hole outside the land" % tag(v)


@test
def test_cable_exits_back():
    """From the bump, in every pose, straight out the back is clear."""
    for v in VARIANTS:
        for name, pose in FAN_POSES.items():
            probe = ("fan_pose() for (i = [0:3:40]) translate([0,0,i]) intersection(){ %s"
                     " difference(){ cube(200, center=true); translate([-fan_size/2,-fan_size/2,-1])"
                     " cube([fan_size, fan_size, 300]); } }" % pose)
            assert is_empty("intersection(){dock(); %s}" % probe, vd(v)), "%s %s: cable blocked" % (tag(v), name)


@test
def test_fan_slot_isolated():
    """The slot keeps >= wall-0.4 from every seat cut."""
    for v in VARIANTS:
        for m in ["seat_pocket", "exhaust_chamber", "button_notch", "end_windows", "pager_cable_guide"]:
            assert is_empty("intersection(){fan_slot(hole = false); %s(g = wall - 0.4);}" % m, vd(v)), \
                "%s: fan slot breaks into %s" % (tag(v), m)
```

- [ ] **Step 2: Run the new tests and watch them fail**

Run: `python3 -I tests/check.py test_profile test_fan_fits test_fan_seats test_fan_drop test_stack_ret test_slot_clear test_hole_inside test_cable_exits test_fan_slot_iso`
Expected: FAIL (ScadError for undefined `hole2d`, plus deleted/renamed modules).

- [ ] **Step 3: Implement** the Produces list in `body.scad`.
  - Keep every seat module untouched, and keep `behind_slab()` (Task 3 uses it).
  - `pager_cable_guide` uses `Wd` and still works.
  - `coupon()` keeps `cradle_t_*` and `dock()`.
  - In `tools/preview.scad`, the `fan_pose() fan_envelope()` ghosts keep working.

- [ ] **Step 4: Run the new tests, then the whole suite**

Run: `python3 -I tests/check.py test_profile test_fan_fits test_fan_seats test_fan_drop test_stack_ret test_slot_clear test_hole_inside test_cable_exits test_fan_slot_iso`
Expected: all PASS.

If `test_fan_slot_isolated` fails on `button_notch`, `seat_cut_boxes()` is missing a corner. Fix the box; don't weaken the test.

Then run `python3 -I tests/check.py > <workspace>/suite.log` and read its tail.
Expected: every remaining test passes except `test_no_long_bridges`, which may fail until Task 3 adds the chamber posts. Record any other failure as a finding.

- [ ] **Step 5: Commit**

```bash
git add src/body.scad src/dock.scad tests/check.py
git commit -m "feat(v0.2): tapered body and drop-in tilted fan slot with teardrop hole"
```

---

### Task 3: Chamber

**Files:**
- Modify: `src/body.scad`, `tests/check.py`

**Interfaces:**
- Consumes: Task 2's `dock()`, `fan_slot(g, hole)`, `hole2d()`, `behind_slab()`, `clip_wall_posts()`, `intake_duct()`.
- Produces:
  - `below(m, k)`: the half-space `dot(X, m) <= k` for a unit `m` in the YZ plane. Built as `translate(k*m) rotate([atan2(m[2], m[1]), 0, 0]) translate([-500, -1000, -500]) cube(1000)`.
  - `ch_x = max([for (v = vent_lo) each [abs(v[0]), abs(v[1])]]) + vent_margin`, then `max(that, hole_r) + 1`.
  - `ch_floor`: the lower of `(fan_origin() - hole_r*fan_u() - wall*fan_n())[2]` and `pose_pt([0, -pg_W/2 - duct_w, pg_zc - pg_T/2 - seat_clear - wall - duct_dip])[2]`, minus 1.
  - `ch_cap = (fan_origin() + hole_r*fan_u() - wall*fan_n()) * slope_t() + 1`.
  - `chamber()`, the intersection of:
    - `behind_slab()`;
    - `below([0,0,-1], -ch_floor)`;
    - `below(fan_n(), fan_origin()*fan_n() - wall)`;
    - `below(slope_t(), ch_cap)`;
    - `translate([-ch_x, -500, -500]) cube([2*ch_x, 1000, 1000])`.

    Then subtract `pager_pose() gbox(pg_clip_box, clip_relief + wall)` and `clip_wall_posts()`.
  - `dock()` subtracts `chamber()` after `fan_slot()`.

- [ ] **Step 1: Write the failing tests**

```python
ROOM_AIR = ["seat_pocket", "end_windows", "exhaust_chamber", "button_notch", "pager_cable_guide"]


@test
def test_chamber_reaches_hole():
    for v in VARIANTS:
        probe = "fan_pose() translate([0,0,-wall-1.5]) linear_extrude(1) offset(-0.5) hole2d();"
        assert is_empty("difference(){ %s chamber(); }" % probe, vd(v)), "%s: chamber misses the hole" % tag(v)


@test
def test_intake_joins_chamber():
    for v in VARIANTS:
        d = vd(v)
        _, dst = run_scad("intersection(){ intake_duct(); chamber(); }", d)
        bb = stl_bbox(dst) if dst.exists() else None
        assert bb, "%s: intake duct never reaches the chamber" % tag(v)
        vl = P("vent_lo", d)
        assert bb[0][0] <= vl[0][0] and bb[1][0] >= vl[1][1], "%s: overlap %r" % (tag(v), bb)


@test
def test_exhaust_isolated():
    for v in VARIANTS:
        for m in ROOM_AIR:
            assert is_empty("intersection(){chamber(); %s(g = wall - 0.4);}" % m, vd(v)), \
                "%s: %s leaks into the chamber" % (tag(v), m)


@test
def test_slot_isolated_from_chamber():
    for v in VARIANTS:
        assert is_empty("intersection(){chamber(); fan_slot(g = wall - 0.4, hole = false);}", vd(v)), \
            "%s: slot leaks into the chamber outside the hole" % tag(v)


@test
def test_chamber_sealed():
    """Plug the slot (hole included) and the intake: exactly one enclosed void remains."""
    for v in VARIANTS:
        log, _ = run_scad("union(){ dock(); intake_duct(); fan_slot(); }", vd(v))
        vols = re.findall(r"Volumes:\s+(\d+)", log)
        assert vols and int(vols[-1]) == 3, "%s: %s volumes (3 = sealed)" % (tag(v), vols[-1:])
```

Update `test_no_long_bridges` to loop `VARIANTS` with `vd(v)` if Task 2 didn't already.

- [ ] **Step 2: Run them and watch them fail**

Run: `python3 -I tests/check.py test_chamber test_intake_joins test_exhaust_iso test_slot_isolated_from`
Expected: FAIL (`chamber` undefined).

- [ ] **Step 3: Implement** the Produces list.

- [ ] **Step 4: Run the tests and watch them pass, then run the bridge check and the suite**

Run: `python3 -I tests/check.py test_chamber test_intake_joins test_exhaust_iso test_slot_isolated_from test_no_long_bridges`
Expected: all PASS.

If `test_no_long_bridges` reports a hanging edge longer than 25 mm, read its height and position. Find the feature at that spot, and fix it with a 45° chamfer or the existing post pattern (never a solid fill).

Then run the full suite. Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/body.scad tests/check.py
git commit -m "feat(v0.2): small chamber from the fan hole to the intake"
```

---

### Task 4: Filter frames, fan gauge, single coupon and gasket

**Files:**
- Create: `src/filter.scad`
- Modify: `src/lib.scad`, `src/body.scad` (`fan_gauge`), `src/dock.scad`, `tests/check.py`

**Interfaces:**
- Consumes: the fan params, `slot_local()`, `fan_housing_local()`.
- Produces:
  - `filter_grid()`: printed flat, z ∈ [0, `frame_t`].
    - An outer square of `fan_size` with a border of width `filter_border`.
    - Grid bars `grid_bar` wide at `grid_pitch`, across the opening.
    - 4 corner pegs `peg_d`, centred `filter_border/2` in from both edges, from z = `frame_t` up to `2*frame_t + filter_gap - 0.2`.
  - `filter_cap()`: the same border, no grid, with 4 holes of `peg_d + peg_fit` at the peg centres. z ∈ [0, `frame_t`].
  - `fan_gauge()`: `intersection(){ difference(){ fan_housing_local(); slot_local(); } translate([-500, -500, -500]) cube([1000, 500 - fan_size/2 + 12, 1000]); }` (fan-local, local y ≤ −`fan_size/2` + 12), then rotated with `rotate([90,0,0])` so local y points up, and translated to sit on z = 0.
  - `dock.scad` parts: `"fan-gauge"` → `fan_gauge()`; `"filter-grid"` → `filter_grid()`; `"filter-cap"` → `filter_cap()`.

- [ ] **Step 1: Write the failing tests**

```python
@test
def test_filter_frames():
    ft, gap, stack, bar, pitch = P("[frame_t, filter_gap, filter_stack, grid_bar, grid_pitch]")
    approx(stack, 2 * ft + gap, 1e-9)
    assert (pitch - bar) ** 2 / pitch ** 2 >= 0.70, "grid open area"
    for fs in (40, 60):
        d = {"fan_size": fs}
        _, g = run_scad("filter_grid();", d)
        _, c = run_scad("filter_cap();", d)
        (glo, ghi), (clo, chi) = stl_bbox(g), stl_bbox(c)
        approx(ghi[0] - glo[0], fs, 0.01)
        approx(chi[2] - clo[2], ft, 0.01)
        assert ghi[2] > ft + gap + 0.5, "%d: pegs don't reach into the cap" % fs
        assert is_empty("intersection(){ filter_grid(); translate([0,0,frame_t + filter_gap]) filter_cap(); }", d), \
            "%d: pegs don't pass the cap's holes" % fs
        for part in (g, c):
            hanging, ceilings = bridges(stl_facets(part))
            assert not hanging or max(hanging) <= 25.1, "%d: frame bridges %r" % (fs, max(hanging))


@test
def test_spacer_slack():
    """Empty frames as a spacer (no media): the fan still can't move more than 1.5 mm off its land."""
    for v in VARIANTS:
        e = ("translate(%s*fan_n()) fan_pose() { fan_envelope();"
             " translate([-fan_size/2, -fan_size/2, fan_t]) cube([fan_size, fan_size, 2*frame_t]); }")
        assert not is_empty("intersection(){dock(); %s}" % (e % "1.5"), vd(v)), "%s: too much slack" % tag(v)


@test
def test_fan_gauge():
    for fs, t in ((40, 20), (60, 25)):
        d = {"fan_size": fs, "fan_t": t}
        _, g = run_scad("fan_gauge();", d)
        lo, hi = stl_bbox(g)
        approx(lo[2], 0, 0.01)
        assert hi[2] - lo[2] <= P("hx", d) - fs / 2 + 12 + 0.1
        hanging, _ = bridges(stl_facets(g))
        assert not hanging or max(hanging) <= 25.1, "%d gauge bridges %r" % (fs, max(hanging))


@test
def test_coupon_small():
    _, dst = run_scad("coupon();")
    lo, hi = stl_bbox(dst)
    approx(lo[2], 0, 0.01)
    assert hi[2] - lo[2] <= P("seat_depth + seat_clear + wall") + 0.5


@test
def test_gasket_fits_groove():
    assert is_empty("intersection(){dock(); gasket_seated();}"), "gasket collides with the dock"
    assert not is_empty("intersection(){pager_pose() pager_envelope(); gasket_seated();}"), "gasket doesn't seal"
```

- [ ] **Step 2: Run them and watch them fail**

Run: `python3 -I tests/check.py test_filter_frames test_spacer test_fan_gauge test_coupon_small test_gasket_fits`
Expected: frames, spacer and gauge FAIL with undefined modules. The coupon and gasket tests may pass already; they are re-added coverage, not new behaviour.

- [ ] **Step 3: Implement** `filter.scad`, `fan_gauge()` and the `dock.scad` parts. Add `include <filter.scad>` to `lib.scad`.

- [ ] **Step 4: Run them and watch them pass, then run the suite**

Run: the same as Step 2. Expected: 5 passed. Then the full suite: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/filter.scad src/lib.scad src/body.scad src/dock.scad tests/check.py
git commit -m "feat(v0.2): snap-together filter frames and fan-slot gauge"
```

---

### Task 5: Build outputs and README

**Files:**
- Modify: `Makefile`, `README.md`, `tools/preview.scad` (only if it needs `fan_t`)
- Delete: `stl/{dock,coupon,gasket}-{80,92,120}.stl` and `previews/*-{80,92,120}.png`

**Interfaces:**
- Consumes: all parts.
- Produces:
  - `stl/dock-{60x15,60x25,40x10,40x20}.stl`
  - `stl/filter-grid-{40,60}.stl`, `stl/filter-cap-{40,60}.stl`
  - `stl/fan-gauge-{40,60}.stl` (fan_t 20 / 25)
  - `stl/coupon.stl`, `stl/gasket.stl`, `stl/fit-gauge.stl`
  - `previews/{front,rear,section}-<variant>.png`

- [ ] **Step 1: Makefile**
  - `VARIANTS := 60x15 60x25 40x10 40x20`.
  - The dock rule gets its values with `-D fan_size=$(word 1,$(subst x, ,$*)) -D fan_t=$(word 2,$(subst x, ,$*))`.
  - Add explicit rules for the filter, gauge, coupon and gasket outputs.
  - Preview rules take the same two `-D` values.
  - `make stl previews` must build exactly the Produces list.

- [ ] **Step 2: Remove the old outputs and build**

```bash
git rm -q stl/dock-80.stl stl/dock-92.stl stl/dock-120.stl stl/coupon-*.stl stl/gasket-*.stl previews/*-80.png previews/*-92.png previews/*-120.png
make -j6 stl previews
```

Expected: exit 0, with no WARNING in the log. `ls stl previews` lists exactly the Produces files plus `fit-gauge.stl`.

- [ ] **Step 3: README**
  - **Intro and air path:** say that the fan sits upright at the back and its air hole feeds a short chamber.
  - **Variants table:** the four variants, with their real sizes taken from `stl_bbox`.
  - **Fan section:**
    - faces back, drops in from above;
    - the cable leaves at a lower corner, straight out the back;
    - flip it for pull mode.
  - **Filter section:**
    - how to cut MERV 8 media from the pleated panel (peel the backing mesh if it comes off easily, otherwise keep it on the fan side);
    - cut squares to `fan_size − 1`;
    - press the media onto the grid frame's pegs and snap the cap on;
    - slide the stack in behind the fan;
    - with no media, snap the frames together empty as a spacer;
    - leave the filter out in pull mode.
  - **Printing:**
    - supports OFF;
    - the solid body outside the chamber prints as sparse infill, so use about 10 % infill (the user asked for this note);
    - the frames print flat, grid down;
    - print the fan gauge before a full dock.
  - **Remove:** the Noctua grill paragraph (no 40/60 grills; the grid acts as a finger guard in push mode), and the cable channel and adapter text.
  - **Keep:** the caliper list and the credits.

- [ ] **Step 4: Full suite and a look at the previews**

Run: `python3 -I tests/check.py > <workspace>/suite.log; tail -3 <workspace>/suite.log`
Expected: `N passed, 0 failed`.

Then open `previews/section-60x25.png` and `previews/rear-40x10.png` and confirm:
- the chamber runs from the hole to the intake;
- the slot is open at the top;
- the body tapers toward the fan.

- [ ] **Step 5: Commit**

```bash
git add -A Makefile README.md tools/preview.scad stl previews
git commit -m "build(v0.2): 60/40 variants, filter frames, gauges; readme"
```
