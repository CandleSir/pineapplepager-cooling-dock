# Pager Dock v0.3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the filter its own slot behind a divider so the fan always seats on its land, cut a floating toe into the front edge, and slope the roof down toward the back as steep as each fan allows.

**Architecture:**
- `params.scad` gains the new numbers; `slot_depth` becomes fan-only and two derived depths (`filt_depth`, `housing_depth`) size the housing.
- `body.scad`'s `slot_local()` grows a divider with a four-sided window and a second slot behind it; the reliefs and scallops run through both. Two new half-space cuts, `toe_cut()` and `roof_cut()`, are subtracted in `dock()` after the hull. Nothing in the seat changes.
- The fan gauge becomes per variant. Tests in `tests/check.py` follow the same probe-and-`is_empty` style as today.

**Tech Stack:** OpenSCAD 2021.01 (CGAL, slow: filter test runs with `python3 -I tests/check.py <substring>`), Python 3 stdlib test harness, GNU make, git-lfs.

**Spec:** `docs/superpowers/specs/2026-10-21-pager-dock-v0.3-design.md` (builds on `2026-10-19-pager-dock-v0.2-design.md`).

## Global Constraints

- Printing: Bambu P1S, PLA Matte, standing on the base, **supports OFF**; no hanging edge or flat ceiling over `bridge_max = 25` (`test_no_long_bridges`); no feature that only the thick fan would fit.
- Seat frozen: no change to any `seat_*`, `pg_*`, vent, port or button parameter, nor to `pocket_plan`, `seat_pocket`, `end_windows`, `intake_duct`, `exhaust_chamber`, `bar_grille`, `button_notch`, `gasket_groove`, `pager_cable_guide`, `fit_gauge`, `gasket*`, `chamber`.
- Fan pose frozen: `fan_tilt = 15`, `fan_origin()`, `hole2d()`, `fan_clear = 0.3`, `fan_clear_z = 0.5`, `fan_ledge`, `fan_lip = 3`, the cable reliefs and their 45° roofs.
- Variants: exactly 60x15, 60x25, 40x10, 40x20 via `-D fan_size= -D fan_t=`.
- New values, verbatim from the spec: `div_t = 1.6`, `filter_clear = 0.5`, `filter_clear_z = 0.8`, `filter_gap = 1.2`, `toe = 24`, `roof_keep = 4`; `roof_angle` derived unless forced with `-D`, clamped at 0.
- The 40 mm filter frames the user already printed must still fit: frames stay `fan_size` square; the filter slot is the wider one.
- Every parameter stays `-D`-overridable and lives in `src/params.scad`.
- Git: branch `v0.3` off `main`; never add `Co-Authored-By` or any AI attribution; `*.stl` and `*.png` are LFS-tracked already; commit after every task.

## Review Focus

1. A thinner-than-gap media (pegs standing proud by up to `filter_clear_z`): the stack must still slide into the filter slot. Test in Task 1 (`test_filter_slot` drops a stack `filter_stack + filter_clear_z - 0.1` thick).
2. Pull mode, filter slot empty: the fan must still be held at the land by the divider, not float back. Test in Task 1 (`test_fan_slot_depth`).
3. The fan cable, in both poses, now has to pass the divider and the rear wall: `test_cable_exits_back` (existing) must pass unchanged in Task 1.
4. The roof on the 60x25, the shallowest: the window's chamfered top and the lips must survive above the fan. Test in Task 5 (`test_roof_keep`), run for all variants.
5. `-D roof_angle=` forced steeper than the fan allows: the spec allows forcing; the plan does not guard it. The README says it is at the user's risk (Task 6).

---

### Task 1: Fan slot at fan depth, divider, filter slot

**Files:**
- Modify: `src/params.scad` (section `---- Fan slot and filter`)
- Modify: `src/fan.scad:32` (`housing_box`)
- Modify: `src/body.scad:27-52` (`slot_local`)
- Test: `tests/check.py` (`STACK`, `test_profile`, `test_fan_fits`, `test_fan_drop_in`, `test_fan_grip`, `test_stack_retained`, `test_spacer_slack`, `test_filter_frames`, new tests)

**Interfaces:**
- Produces, in `params.scad`: `div_t`, `filter_clear`, `filter_clear_z`, `filter_gap = 1.2`, `slot_depth = fan_t + fan_clear_z`, `filt_depth = filter_stack + filter_clear_z`, `housing_depth = slot_depth + div_t + filt_depth`.
- Produces, in `body.scad`: `function window_flat() = min(bridge_max, 2*(fan_size/2 - fan_lip))`, `module window2d()` (the four-sided window outline in the fan frame, centred), `slot_local(g, hole)` with the new cuts.
- `housing_box` z-max becomes `housing_depth + wall`. Tasks 3 and 5 read `housing_depth`.

- [ ] **Step 1: Write the failing tests**

Replace `STACK` and the two retired tests; add the new ones next to `test_slot_clearance`:

```python
# FAN_POSES already hold the fan alone; drop STACK and its "%s %s" % (pose, STACK) uses
# the filter stack, frames at fan_size, media of exactly filter_gap: sits on the divider
FILTER = ("translate([-fan_size/2, -fan_size/2, slot_depth + div_t + 0.01])"
          " cube([fan_size, fan_size, filter_stack]);")
# ... in test_fan_fits / test_fan_drop_in: "%s %s" % (pose, STACK) -> "%s" % pose

@test
def test_filter_slot():
    """The filter stack drops into its own slot behind the divider, and a stack with
    pegs standing proud by the slot's slack still goes in; the slot is 0.5/side and 0.8 deep clear."""
    for v in VARIANTS:
        d = vd(v)
        assert is_empty("intersection(){dock(); for (i = [0:5:120]) translate(i*fan_u() + 0.01*fan_n())"
                        " fan_pose() { %s }}" % FILTER, d), "%s: filter drop-in blocked" % tag(v)
        proud = ("translate([-fan_size/2, -fan_size/2, slot_depth + div_t + 0.01])"
                 " cube([fan_size, fan_size, filter_stack + filter_clear_z - 0.1]);")
        assert is_empty("intersection(){dock(); fan_pose() %s}" % proud, d), "%s: proud pegs jam" % tag(v)
        z = "slot_depth + div_t + 1"
        assert not is_empty("intersection(){dock(); fan_pose() translate([fan_size/2 + filter_clear + 0.05, -5, %s])"
                            " cube([0.25, 10, 2]);}" % z, d), "%s: filter side wall not at filter_clear" % tag(v)
        assert is_empty("intersection(){dock(); fan_pose() translate([fan_size/2, -5, %s])"
                        " cube([filter_clear - 0.05, 10, 2]);}" % z, d), "%s: filter side wall inside filter_clear" % tag(v)
        assert not is_empty("intersection(){dock(); fan_pose() translate([-1, fan_size/2 - 2.5, housing_depth + 0.05])"
                            " cube([2, 1, wall - 0.1]);}", d), "%s: no rear lip behind the filter" % tag(v)


@test
def test_fan_slot_depth():
    """Fan alone: seats on the land, and the divider stops it fan_clear_z back."""
    for v in VARIANTS:
        d = vd(v)
        assert is_empty("intersection(){dock(); translate((fan_clear_z - 0.05)*fan_n()) fan_pose() fan_envelope();}", d), \
            "%s: slot shallower than fan_t + fan_clear_z" % tag(v)
        assert not is_empty("intersection(){dock(); translate((fan_clear_z + 0.3)*fan_n()) fan_pose() fan_envelope();}", d), \
            "%s: divider doesn't hold the fan" % tag(v)


@test
def test_divider_window():
    """The divider is div_t thick, open through the middle, closed on all four sides inside the
    frame's border, and its flat top is a printable bridge."""
    assert P("filter_border - fan_lip") >= 1, "frame border must land on the lips"
    for v in VARIANTS:
        d = vd(v)
        assert P("window_flat()", d) <= P("bridge_max", d), tag(v)
        assert is_empty("intersection(){dock(); fan_pose() translate([-2, -2, slot_depth - 0.5]) cube([4, 4, div_t + 1]);}", d), \
            "%s: window not open" % tag(v)
        for where in ("[-1, fan_size/2 - 2.5, slot_depth + 0.05]",       # top lip
                      "[-1, -fan_size/2 + 1.5, slot_depth + 0.05]",      # bottom lip
                      "[fan_size/2 - 2.5, 8, slot_depth + 0.05]"):       # side lip, above the relief roofs
            assert not is_empty("intersection(){dock(); fan_pose() translate(%s) cube([2, 1, div_t - 0.1]);}" % where, d), \
                "%s: no lip at %s" % (tag(v), where)
```

Also edit in place:
- `test_profile`: `slot_depth + wall` → `housing_depth + wall`.
- `test_fan_grip`: probe depth `slot_depth - 1` → `housing_depth - 1` (scallops serve both slots).
- `test_filter_frames`: no change to assertions; it must pass with `filter_gap = 1.2`.
- Delete `test_stack_retained` and `test_spacer_slack`.

- [ ] **Step 2: Run the new tests to see them fail**

Run: `python3 -I tests/check.py filter_slot fan_slot_depth divider_window`
Expected: FAIL (`div_t` undefined / `housing_depth` undefined in the echo).

- [ ] **Step 3: Parameters**

In `src/params.scad`, section `---- Fan slot and filter`: set `filter_gap = 1.2`; add `div_t = 1.6`, `filter_clear = 0.5`, `filter_clear_z = 0.8`; replace `slot_depth = fan_t + filter_stack + fan_clear_z` with

```scad
slot_depth = fan_t + fan_clear_z;                 // fan slot: land to divider
filt_depth = filter_stack + filter_clear_z;       // filter slot: divider to rear lips
housing_depth = slot_depth + div_t + filt_depth;  // land to the rear wall's inner face
```

Comment each new value the way the file does (one line, what it is and why).

- [ ] **Step 4: Housing and slot**

`src/fan.scad`: `housing_box` z-max `slot_depth + wall` → `housing_depth + wall`.

`src/body.scad`, `slot_local(g, hole)`: keep the fan slot cube at `slot_depth + 2*g` deep. Replace the open-top window cube with:

```scad
// divider between the slots: window closed on four sides, 45 deg top corners so the flat
// top bridges no more than bridge_max (same trick as the teardrop hole)
translate([0, 0, slot_depth - 0.01 - g]) linear_extrude(div_t + 0.02 + 2*g) offset(delta = g) window2d();
// filter slot, open at the top, filter_clear per side
b = fan_size/2 + filter_clear + g;
translate([-b, -b, slot_depth + div_t - g]) cube([2*b, 200, filt_depth + 2*g]);
// rear window out the back, same outline
translate([0, 0, housing_depth - 0.01 - g]) linear_extrude(100) offset(delta = g) window2d();
```

with, above `slot_local`:

```scad
function window_flat() = min(bridge_max, 2*(fan_size/2 - fan_lip));
module window2d() let(w = fan_size/2 - fan_lip, c = w - window_flat()/2)
    polygon([[-w, -w], [w, -w], [w, w - c], [window_flat()/2, w], [-window_flat()/2, w], [-w, w - c]]);
```

Scallops: depth `slot_depth + 2*g` → `housing_depth + 2*g`. Reliefs, roofs and hole unchanged (they already run through).

- [ ] **Step 5: Run the slot tests**

Run: `python3 -I tests/check.py filter_slot fan_slot_depth divider_window fan_fits fan_drop_in fan_grip fan_seats profile slot_clearance cable_exits fan_slot_isolated filter_frames`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add src/params.scad src/fan.scad src/body.scad tests/check.py
git commit -m "feat(v0.3): filter slot behind a divider; fan slot is fan-depth"
```

---

### Task 2: Air path and print checks still hold

**Files:**
- Test: `tests/check.py` (existing tests only)

**Interfaces:** none new. This task exists so a reviewer can reject the housing change on its own if it leaks or bridges.

- [ ] **Step 1: Run the chamber, seal and bridge tests on every variant**

Run: `python3 -I tests/check.py chamber slot_isolated exhaust_isolated no_long_bridges hole_inside hole_under housing_on_desk fan_clear_of`
Expected: all PASS. If `test_no_long_bridges` reports a hanging edge of `window_flat()` length, it is ≤ 25.1 by construction; anything longer means `window2d()` is wrong, fix it in `body.scad`.

- [ ] **Step 2: Commit** (only if a fix was needed)

```bash
git commit -am "fix(v0.3): <what the window needed>"
```

---

### Task 3: Fan gauge per variant

**Files:**
- Modify: `Makefile` (`GAUGES`, `GAUGE_T_*`, `stl/fan-gauge-%.stl` rule)
- Modify: `tests/check.py` (`test_fan_gauge`)
- Remove: `stl/fan-gauge-40.stl`, `stl/fan-gauge-60.stl`

**Interfaces:**
- Produces: `stl/fan-gauge-{60x15,60x25,40x10,40x20}.stl` targets, built with `$(call fan,$*)` like the docks.

- [ ] **Step 1: Write the failing test**

Rewrite `test_fan_gauge` to loop `for v in VARIANTS: d = vd(v)` (keep every existing assertion, message tags via `tag(v)`), and add inside the loop:

```python
        # the gauge now carries the divider: its bottom lip is div_t thick, exactly slot_depth back
        # (gauge frame: fan x -> x, fan z -> -y, fan y -> z + hx; probe at the slot's centreline,
        # clear of the corner reliefs)
        assert not is_empty("intersection(){ fan_gauge(); translate([-1, -(slot_depth + div_t - 0.05),"
                            " hx - fan_size/2 + 1.5]) cube([2, div_t - 0.1, 1]); }", d), "%s: gauge has no divider" % tag(v)
        assert is_empty("intersection(){ fan_gauge(); translate([-1, -(slot_depth - 0.05), hx - fan_size/2 + 1.5])"
                        " cube([2, 0.25, 1]); }", d), "%s: gauge slot shallower than slot_depth" % tag(v)
```

- [ ] **Step 2: Run it to see it fail**

Run: `python3 -I tests/check.py fan_gauge`
Expected: PASS already. The gauge is built from the modules Task 1 fixed, so the model is right for every variant; this step only pins all four. What is wrong is the build: `make stl` still produces two gauges cut for the thick fans.

- [ ] **Step 3: Makefile**

```make
GAUGES := $(VARIANTS:%=stl/fan-gauge-%.stl)
...
stl/fan-gauge-%.stl: $(SRC)
	$(OUT) -D 'part="fan-gauge"' $(call fan,$*) src/dock.scad
```

Delete `GAUGE_T_40`/`GAUGE_T_60`. `git rm stl/fan-gauge-40.stl stl/fan-gauge-60.stl`.

- [ ] **Step 4: Run the gauge test and build the gauges**

Run: `python3 -I tests/check.py fan_gauge && make stl/fan-gauge-40x10.stl stl/fan-gauge-60x25.stl`
Expected: PASS; two STLs appear (the other two come with `make stl` in Task 6).

- [ ] **Step 5: Commit**

```bash
git add Makefile tests/check.py stl/fan-gauge-*.stl
git commit -m "feat(v0.3): fan gauge per variant, slot at fan depth"
```

---

### Task 4: Floating toe

**Files:**
- Modify: `src/params.scad` (new section `---- Toe and roof`)
- Modify: `src/body.scad` (`below`, new `above`, `toe_cut`, `dock`)
- Test: `tests/check.py` (`test_profile`, new `test_toe`)

**Interfaces:**
- Produces: `toe = 24`; `module above(m, k)` (half-space `dot(X, m) >= k`, the mirror of `below`); `module toe_cut(g = 0)` (the removed wedge: `dot(X, [0, 1, 1]/sqrt(2)) <= toe/sqrt(2) + g`); `dock()` subtracts `toe_cut()`.

- [ ] **Step 1: Write the failing test**

```python
@test
def test_toe():
    """The front edge floats: nothing in front of the 45 deg plane from y = toe on the desk,
    a 90 deg edge at (toe/2, toe/2), and the cut stays >= wall from every cavity."""
    for v in VARIANTS:
        d = vd(v)
        assert is_empty("intersection(){dock(); translate([-5, -1, -1]) cube([10, toe, 1.5]);}", d), \
            "%s: desk contact in front of toe" % tag(v)
        assert not is_empty("intersection(){dock(); translate([-5, toe + 0.1, 0]) cube([10, 1, 0.5]);}", d), \
            "%s: no desk contact at toe" % tag(v)
        assert not is_empty("intersection(){dock(); translate([-5, toe/2 + 0.6, toe/2 + 0.3]) cube([10, 0.2, 0.2]);}", d), \
            "%s: edge missing at (toe/2, toe/2)" % tag(v)
        assert is_empty("intersection(){dock(); translate([-5, toe/2 - 0.5, toe/2 - 0.5]) cube([10, 0.2, 0.2]);}", d), \
            "%s: material in front of the edge" % tag(v)
        for m in ["chamber", "intake_duct", "seat_pocket", "end_windows", "pager_cable_guide"]:
            assert is_empty("intersection(){toe_cut(g = wall - 0.4); %s();}" % m, d), \
                "%s: toe cut within a wall of %s" % (tag(v), m)
```

In `test_profile` add `approx(lo[1], P("toe", d)/2, 0.05)` after the bbox checks (the model's y origin is the old front-bottom edge).

- [ ] **Step 2: Run it to see it fail**

Run: `python3 -I tests/check.py test_toe profile`
Expected: FAIL (`toe` undefined).

- [ ] **Step 3: Implement**

`src/params.scad`, new section before `---- Printing`:

```scad
// ---- Toe and roof
toe = 24;          // 45 deg undercut under the front edge, starting this far back on the desk
```

`src/body.scad`: next to `below(m, k)` add `module above(m, k) below(-m, -k);`. Add

```scad
// Floating toe: everything in front of the 45 deg plane rising from the desk at y = toe
module toe_cut(g = 0) below([0, 1, 1]/sqrt(2), toe/sqrt(2) + g);
```

and subtract `toe_cut();` in `dock()`'s `difference()`, after `pager_cable_guide();`.

- [ ] **Step 4: Run the tests**

Run: `python3 -I tests/check.py test_toe profile no_long_bridges chamber_sealed coupon fit_gauge`
Expected: all PASS (`test_coupon_small` and `test_fit_gauge` prove the seat parts ignore the toe).

- [ ] **Step 5: Commit**

```bash
git add src/params.scad src/body.scad tests/check.py
git commit -m "feat(v0.3): floating toe under the front edge"
```

---

### Task 5: Roof sloping down toward the back

**Files:**
- Modify: `src/params.scad` (`---- Toe and roof`)
- Modify: `src/body.scad` (`crest`, `roof_a`, `roof_cut`, `dock`, `cradle_t_hi`)
- Test: `tests/check.py` (`test_profile`, new `test_roof`)

**Interfaces:**
- Produces: `roof_keep = 4`, `roof_angle = undef`; `function crest() = [0, H*cos(seat_angle)/sin(seat_angle), H]`; `function roof_req() = fan_pt([0, fan_size/2 + fan_clear + roof_keep, housing_depth + wall])`; `function roof_a()` (degrees, forced value if `!is_undef(roof_angle)`, else `max(0, atan2(crest()[2] - roof_req()[2], roof_req()[1] - crest()[1]))`); `module roof_cut(g = 0)` = `above(m, crest()*m - g)` with `m = [0, sin(roof_a()), cos(roof_a())]`.

- [ ] **Step 1: Write the failing test**

```python
@test
def test_roof():
    """One plane from the crest down toward the back: it takes the old flat top, sits at roof_a(),
    keeps roof_keep above the housing's rear-top edge, and stays >= wall from every cavity."""
    for v in VARIANTS:
        d = vd(v)
        a, cy, H = P("[roof_a(), crest()[1], H]", d)
        assert 0 < a < 60, "%s: roof_a %.1f" % (tag(v), a)
        drop = 30 * math.tan(math.radians(a))
        # a thin full-width slice 30 mm behind the crest: its top is the roof plane (the slot
        # well is open there, but the slot's side walls and the hull reach the roof)
        _, s = run_scad("intersection(){dock(); translate([-500, %s, -500]) cube([1000, 0.2, 1000]);}" % (cy + 30), d)
        approx(stl_bbox(s)[1][2], H - drop, 0.3)
        # rear wall survives roof_keep above the housing's rear-top edge, at the slot's centreline
        assert not is_empty("intersection(){dock(); fan_pose() translate([-1, fan_size/2 + fan_clear + roof_keep - 0.6,"
                            " housing_depth + 0.2]) cube([2, 0.5, wall - 0.4]);}", d), "%s: roof cuts below roof_keep" % tag(v)
        for m in ["chamber", "exhaust_chamber", "button_notch", "gasket_groove", "seat_pocket", "end_windows"]:
            assert is_empty("intersection(){roof_cut(g = wall - 0.4); %s();}" % m, d), \
                "%s: roof within a wall of %s" % (tag(v), m)
    assert P("cradle_t_hi") <= P("seat_u_top") + 1e-6, "coupon box reaches past the crest"
```

Forced angle: add to the same test `approx(P("roof_a()", dict(vd((40, 10)), roof_angle=30)), 30, 1e-9)`.

- [ ] **Step 2: Run it to see it fail**

Run: `python3 -I tests/check.py test_roof`
Expected: FAIL (`roof_a` undefined).

- [ ] **Step 3: Implement**

`src/params.scad`, `---- Toe and roof`:

```scad
roof_keep = 4;       // the roof stops this far above the housing's rear-top edge, up the fan plane
roof_angle = undef;  // deg down toward the back; derived from roof_keep unless forced with -D
```

`src/body.scad`: the four functions from Interfaces, `roof_cut`, subtract `roof_cut();` in `dock()` after `toe_cut();`. Change `cradle_t_hi` to `min(seat_u0 + pg_W + seat_clear + notch_len + wall + 3, seat_u_top)` so the coupon's box stops at the crest.

Before touching `cradle_t_hi`, record the coupon's volume: `python3 -I -c "import sys; sys.path.insert(0, 'tests'); import check; print(check.stl_volume('stl/coupon.stl'))"`. After the change, `make stl/coupon.stl` and compare: equal within 0.1 %. If not, the box clip is wrong.

- [ ] **Step 4: Run the tests**

Run: `python3 -I tests/check.py test_roof profile no_long_bridges chamber_sealed fan_drop_in filter_slot fan_grip button_notch pinch coupon`
Expected: all PASS. `test_profile`'s `approx(hi[2], H, 0.5)` still holds because the crest stays at `H`.

- [ ] **Step 5: Commit**

```bash
git add src/params.scad src/body.scad tests/check.py stl/coupon.stl
git commit -m "feat(v0.3): roof slopes down toward the back, as steep as the fan allows"
```

---

### Task 6: Full test run, parts, previews, README

**Files:**
- Modify: `README.md` (Air path item 1, Variants table, Other parts table, Using it → Fan, Dust filter steps 3–5, Printing → Dock and Fan gauge, Override example)
- Regenerate: `stl/*.stl` (dock, filter, gauge; coupon from Task 5), `previews/*.png`

**Interfaces:** none.

- [ ] **Step 1: Full test run**

Run: `make test`
Expected: `N passed, 0 failed`.

- [ ] **Step 2: Build everything**

Run: `make stl previews`
Expected: 4 docks, 4 filter frames, 4 gauges, coupon, gasket, fit gauge, 12 PNGs. Look at `previews/front-40x10.png` and `previews/section-60x25.png`: the toe floats, the roof falls toward the back, the filter slot shows behind the divider.

- [ ] **Step 3: README**

Dimensions for the Variants table: `python3 -I -c "import sys; sys.path.insert(0, 'tests'); import check; [print(v, [round(h - l, 0) for l, h in zip(*check.stl_bbox('stl/dock-%dx%d.stl' % v))]) for v in check.VARIANTS]"`.

Edits, in the README's own voice:
- Air path 1: the filter sits in its own slot behind the fan.
- Other parts: `stl/fan-gauge-{60x15,60x25,40x10,40x20}.stl`, "one per variant, the bottom of that fan's slot".
- Using it → Fan: a sentence that the slot is exactly the fan's depth, so it seats with or without the filter.
- Dust filter: step 3 becomes "slide the stack down the slot behind the fan, grid toward the fan; the lips on both sides of that slot hold it"; delete step 4 (empty frames as spacer) and renumber; keep the 39/59 mm media sizes.
- Printing → Dock: add "The front edge is undercut at 45° and the roof slopes toward the back; both print as they are, supports off." Fan gauge: replace "The gauge stands straight and is as deep as the thicker fan, so a thin fan will tip..." with "Print the gauge for your fan; the slot is exactly that fan's depth."
- Override example: mention `-D toe=`, `-D roof_angle=` (forcing a steeper roof than the derived one cuts into the lips; at the user's risk).

- [ ] **Step 4: Commit**

```bash
git add README.md stl previews
git commit -m "build(v0.3): parts, previews, readme"
```

- [ ] **Step 5: Hand back**

Report filament for 40x10 from the user's slicer against v0.2.2 (goal: no more), and the roof angles printed by `python3 -I -c "import sys; sys.path.insert(0,'tests'); import check; [print(v, round(check.P('roof_a()', check.vd(v)), 1)) for v in check.VARIANTS]"`. Merging to `main` and tagging v0.3.0 wait for the user's print.
