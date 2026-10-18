# Pager Cooling Dock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A parametric, single-piece OpenSCAD dock (80/92/120 mm Noctua variants) that holds the Hak5 Pineapple Pager at 45° and forces fan air through its vents, plus a fit-test coupon and an optional TPU gasket.

**Architecture:** One OpenSCAD source tree under `src/`, built around shared parameters (`params.scad`). The Pager and the fan are each modelled as an "envelope" module. The dock is the trapezoid body minus those envelopes and minus the internal air volumes. Tests live in a Python stdlib script that drives the `openscad` CLI. It checks bounding boxes, runs `assert()`s, and does interference checks: the intersection of the dock with a posed part must render empty.

**Tech Stack:** OpenSCAD 2021.01 (installed; CGAL backend, so it is slow — test renders can take minutes), Python 3 stdlib, GNU make, git-lfs 3.8.

**Spec:** `docs/superpowers/specs/2026-10-18-pager-cooling-dock-design.md`

## Global Constraints

- Printer: Bambu P1S. Every part must fit inside 256 × 256 × 256 mm.
- Material: Bambu PLA Matte, 0.4 mm nozzle. Walls ≥ 2 mm.
- The dock is a single piece with no moving parts. The TPU gasket is a separate optional part.
- Seat tilt is the parameter `seat_angle = 45` (degrees from horizontal). Seat clearance is `seat_clear = 0.5` mm per side.
- Fan frames are 80, 92 and 120 mm square, 25 mm thick by default. A parameter `fan_t` supports 14–15 mm slim frames.
- Side profile is a trapezoid:
  - the front face is a 45° slope carrying the Pager;
  - the rear face is a 45° slope the other way carrying the fan, with the fan's bottom edge furthest back;
  - the top is flat, the base is flat, and both slopes are the same height H, set by the fan.
- No supports may be required inside the sealed plenum. Internal roofs must be ≤ 45° overhangs or short bridges.
- Every Pager dimension must be a parameter that caliper values can override.
- Git:
  - Work on branch `dock-v1`, not `main`.
  - Never add `Co-Authored-By` or any AI attribution to commits.
  - `*.stl`, `*.3mf` and `*.step` go through Git LFS. Track them before the first new binary commit.
- README credits Hak5's reference model (CC BY-NC 4.0).

## Review Focus

1. **Clip on vs clip off:** the Pager must seat with no interference either way, and with the clip off it must rest on the floor rather than float. Owner: Task 3 (`test_seat_clip_on_clear`, `test_seat_clip_off_supported`).
2. **Air leaks:** the exhaust chamber, the port window and the vent-end window must not connect to the plenum, otherwise the fan just spins. Owner: Task 4 (`test_exhaust_isolated`).
3. **Fan fit:** a 25 mm fan and a 15 mm slim fan must both drop into the slot either way round, without interfering with the plenum walls. Owner: Task 2 (`test_fan_fits_both_thickness`).
4. **Upper-edge side button:** it must remain reachable. The notch must clear the button's position on the posed Pager. Owner: Task 4 (`test_button_notch_clear`).
5. **Fan cable:** a 4-pin or USB-A plug must never have to thread through a closed hole. The cable channel must be open to the top along its whole length. Owner: Task 5 (`test_cable_channel_open_top`).

---

## File map

| File | Responsibility |
|---|---|
| `src/params.scad` | All numbers: Pager dims, vent/port/button positions, fan table, tolerances, angle, derived H/depth/width |
| `src/pager.scad` | `pager_ref(clip)`, `pager_envelope(clip)`, `pager_pose()` transform |
| `src/fan.scad` | `fan_envelope()`, `fan_pose()` transform |
| `src/dock.scad` | Entry point; `part` = `"dock"`, `"coupon"` or `"gasket"`; `fan_size` selects the variant |
| `src/body.scad` | `body_shell()`, `plenum()`, `exhaust_chamber()`, `intake_duct()`, grilles, windows, channels |
| `tests/check.py` | Test runner (stdlib only), one function per test, CLI `python3 -I tests/check.py [name]` |
| `Makefile` | `make test`, `make stl` (all variants → `stl/`), `make previews` (PNG → `previews/`) |
| `.gitattributes`, `README.md` | LFS rules, how to build/print, attribution |

`tests/check.py` helpers (Task 1 defines them; later tasks reuse them):
- `run_scad(expr: str, defines: dict, timeout=900) -> Path`
  - Writes a temporary `.scad` file that `include`s `src/dock.scad`, then renders `expr` to STL.
  - Raises if OpenSCAD exits non-zero or prints `ERROR` or `Assertion`.
- `stl_bbox(path) -> (min_xyz, max_xyz)`: handles both ASCII and binary STL.
- `is_empty(expr, defines) -> bool`
  - True when OpenSCAD reports `Current top level object is empty`, or when the exported STL has 0 facets.
  - This is the interference primitive: `is_empty("intersection(){dock(); X();}")`.
- `VARIANTS = [80, 92, 120]`. Every geometry test loops over them unless it says otherwise.

---

### Task 1: Repo setup, LFS, parameters, Pager model, test harness

**Files:**
- Create: `.gitattributes`, `src/params.scad`, `src/pager.scad`, `src/dock.scad` (stub), `tests/check.py`, `Makefile`

**Interfaces:**
- Produces:
  - **Pager body parameters** in `params.scad`:
    - `pg_L = 87.0`, `pg_W = 62.5` and `pg_T`, the body thickness without clip or buttons;
    - `pg_r`, the corner radius in plan view, and `pg_edge_r`, the edge fillet;
    - `pg_btn_h = 1.5`, the button height;
    - `pg_clip_t`, `pg_clip_L`, `pg_clip_W`: the clip envelope (thickness below the back, length, width);
    - `pg_origin_to_back`, the distance in STL Z from the origin to the back face.
  - **Vent, port and button positions** in `params.scad`:
    - `vent_lo = [[x0,x1,z0,z1],[x0,x1,z0,z1]]`: the two grilles on the −Y edge;
    - `vent_hi = [x0,x1,z0,z1]`: the grille on the +Y edge;
    - `btn_hi = [x0,x1,z0,z1]`: the side button on the +Y edge;
    - `vent_end = [y0,y1,z0,z1]` and `port_end_sign` (+1 or −1): which X end carries the USB ports.
  - **Fan table** in `params.scad`:
    - `fan_size` (default 120) and `fan_t = 25`;
    - `fan_hole = [71.5, 82.5, 105]` (hole spacing for 80/92/120; reference only);
    - `wall = 2.4`.
  - **Pager modules** in `pager.scad`:
    - `pager_ref(clip=true)`: imports the repo STL, or the body only when `clip=false`;
    - `pager_envelope(clip=true)`: a parametric rounded box plus clip block;
    - `module pager_pose()`: a children transform that places the STL-frame Pager into its docked pose in dock coordinates.
  - **Dock coordinates:**
    - X runs along the dock width, with the Pager's long axis parallel to X;
    - −Y points toward the user;
    - Z points up, with the desk at Z = 0.

- [ ] **Step 1: Branch and set up LFS**

  Run:
  ```bash
  git switch -c dock-v1
  git lfs track "*.stl" "*.3mf" "*.step"
  git add --renormalize .
  git add .gitattributes
  ```
  Expected: `git lfs ls-files` lists both reference files.

  Commit: `chore: track CAD binaries with git lfs`

- [ ] **Step 2: Measure the reference model and record the values in `params.scad`**

  Measure with a stdlib Python scan of the STL, in a throwaway script under the scratchpad. Bin facet centroids that lie within 2 mm inside each outer wall and whose normals are ±X or ±Z (the slot walls), then cluster them into rectangles. Cross-check against close-up perspective renders.

  Mark each vent, port and button value with `// VERIFY BY CALIPER`.

  Also confirm which X end carries the USB-C and USB-A ports. The user says one short end has the two ports and the other has a single vent.

- [ ] **Step 3: Write the failing tests in `tests/check.py`**
  - `test_pager_params_match_stl`: `stl_bbox` of `pager_ref(true)`, taken in the STL frame (no pose), matches `[pg_L, pg_W, pg_T + pg_clip_t + pg_btn_h]` within ±0.3 mm. Expected about 87.0 × 62.5 × 35.4.
  - `test_envelope_contains_ref`: `is_empty("difference(){pager_ref(true); pager_envelope(true);}")`, with a 0.3 mm tolerance allowed via a `minkowski`-free offset parameter `env_grow=0.3`.
  - `test_pose_on_slope`: after `pager_pose()`:
    - the Pager's face normal is 45° from vertical, pointing toward −Y and up;
    - the −Y long edge is the lowest edge;
    - min Z ≥ the lip height parameter `lip_z`.

    Check the normal via `assert()`s inside a test expression module `pose_probe()`.

- [ ] **Step 4: Run the tests and confirm they fail**

  Run: `python3 -I tests/check.py`

  Expected: all three FAIL, with undefined module or variable errors.

- [ ] **Step 5: Implement `params.scad`, `pager.scad` and the `dock.scad` stub, plus the `Makefile` target `test`**

  `dock.scad` must `include` params, pager, fan and body. The modules `dock()`, `coupon()` and `gasket()` are empty stubs for now.

- [ ] **Step 6: Run the tests and confirm they pass**

  Run: `make test`

  Expected: 3 passed.

- [ ] **Step 7: Commit**

  Commit: `feat: pager parameters, pose and test harness`

---

### Task 2: Trapezoid body shell and fan slot

**Files:**
- Create: `src/fan.scad`, `src/body.scad`
- Modify: `src/dock.scad`, `tests/check.py`

**Interfaces:**
- Consumes: the Task 1 parameters and `pager_pose()`.
- Produces:
  - **Derived values** in `params.scad`:
    - `H`: shared slope height. It is the larger of the fan slope height `(fan_size + 2*wall + 2*fan_clear) * sin(45)` and the Pager slope height.
    - `fan_clear = 0.6`.
    - `D`: base depth, equal to `2*H + top_flat`, with `top_flat = 10`.
    - `Wd`: dock width, equal to `max(fan_size, pg_L) + 2*wall + 2*side_margin`.
  - **Fan modules:**
    - `fan_envelope(t=fan_t)`: a square frame block plus the hub, sized `fan_size` × `fan_size` × `t`;
    - `fan_pose()`: tilts the fan 45° to sit on the rear slope with its bottom edge furthest back (+Y).
  - **Body modules:**
    - `body_shell()`: the solid trapezoid prism;
    - `fan_slot()`: the negative volume. It is open at the top and back so the fan drops in from above and behind. Thickness is `fan_t + 2*fan_clear`. It has retaining lips on the rear face.
    - `fan_guard()`: bars on the outer face of the slot, open area ≥ 70 %.

- [ ] **Step 1: Write the failing tests**
  - `test_fits_bed`: for each variant, the `dock()` bbox is ≤ 256 on every axis. Expected for 120: about 140 × 195 × 92.
  - `test_trapezoid_profile`: bbox Z max equals `H` (±0.5), and Y depth equals `D` (±0.5).
  - `test_fan_fits_both_thickness`: for `fan_t` in [25, 15], `is_empty("intersection(){dock(); fan_pose() fan_envelope();}")` is true.
  - `test_fan_fits_flipped`: the same check with the fan mirrored front-to-back inside `fan_pose()`.
  - `test_fan_retained`: translate the fan 3 mm outward along the rear-face normal. It must now intersect the dock, which proves the lips hold it.

- [ ] **Step 2: Run the tests and confirm they fail**

  Run: `make test`

- [ ] **Step 3: Implement `fan.scad`, plus `body_shell`, `fan_slot` and `fan_guard` in `body.scad`, and wire up `dock()`**

  `dock() = difference(){ body_shell(); fan_slot(); }` + `fan_guard()` for now.

- [ ] **Step 4: Run the tests and confirm they pass**

- [ ] **Step 5: Commit**

  Commit: `feat: trapezoid body with tilted drop-in fan slot`

---

### Task 3: Pager seat, clip relief, port window, pinch access

**Files:**
- Modify: `src/body.scad`, `src/dock.scad`, `tests/check.py`

**Interfaces:**
- Produces:
  - `seat_pocket()`: the Pager envelope grown by `seat_clear`, extruded outward along the face normal so it is open on the face side. It includes the clip relief, which is `pager_envelope(true)`'s clip block grown by 1 mm.
  - `lower_lip()`: support under the −Y edge, at height `lip_z = 4`.
  - `port_window()`: the whole port-end short side is open. A frame of at least 3 mm stays around it.
  - `vent_end_window()`: an open window over the vent-end vent.
  - Both windows let you pinch the Pager's short ends: at least 12 mm of finger depth beyond the Pager end, and open to the face side.

- [ ] **Step 1: Write the failing tests**
  - `test_seat_clip_on_clear`: `is_empty(intersection(dock(), pager_pose() pager_ref(true)))`.
  - `test_seat_clip_off_clear`: the same check with `pager_ref(false)`.
  - `test_seat_clip_off_supported`: `pager_pose() translate(-0.8 * face_normal) pager_ref(false)` intersects the dock, so the Pager sits on the floor rather than floating.
  - `test_seat_clip_on_supported`: the same check with the clip on.
  - `test_drop_in_path`: sweep `pager_envelope(true)` 30 mm along the face normal from its seated pose. It must not intersect the dock, which proves nothing overhangs the face.
  - `test_ports_exposed`: a 20 × 15 × 25 mm "fat plug" box centred on each port, extending outward along ±X, does not intersect the dock.

- [ ] **Step 2: Run the tests and confirm they fail**

- [ ] **Step 3: Implement the seat, lip, windows and clip relief in `body.scad`**

  Subtract them inside `dock()`. Note: these tests use the full STL and CGAL, so expect long renders. Keep `$fn` low through the parameter `$fn_test = 24`.

- [ ] **Step 4: Run the tests and confirm they pass**

- [ ] **Step 5: Commit**

  Commit: `feat: drop-in pager seat with clip relief and port window`

---

### Task 4: Air path: plenum, intake duct, isolated exhaust, bar grille, button notch

**Files:**
- Modify: `src/body.scad`, `tests/check.py`

**Interfaces:**
- Produces:
  - `plenum()`: the interior void between the fan slot and the seat floor.
  - `intake_duct()`: connects the plenum to the −Y edge of the seat. Its mouth must cover both `vent_lo` rectangles, extended 1.5 mm on every side, and must not extend past the pocket outline. It must have no perforation.
  - `exhaust_chamber()`: a walled pocket against the +Y edge of the seat, covering `vent_hi` plus 1.5 mm. It exits through `bar_grille()` on the front face above the Pager. The grille's bars are 1.6 mm wide with gaps of at least 3.8 mm, which gives roughly 70 % open area.
  - `button_notch()`: a finger notch at least 14 mm wide over `btn_hi`, open to the face.
  - `gasket_groove()`: a groove 1.2 mm wide and 1.0 mm deep around the intake duct rim.

- [ ] **Step 1: Write the failing tests**
  - `test_exhaust_isolated`: `is_empty(intersection(grow(plenum(), wall-0.4), exhaust_chamber()))`. Apply the same check to the port and vent-end windows. In other words, the separating walls must be at least 2 mm thick.
  - `test_plenum_reaches_fan`: `plenum()` intersects `fan_pose() fan_envelope()` over at least 80 % of the fan disc area. Check this by comparing the bbox of `intersection(plenum(), fan_face_disc())` with the disc's bbox.
  - `test_intake_covers_vents`: for each `vent_lo` rectangle in dock coordinates, `difference(vent_rect_posed(), intake_duct())` is empty.
  - `test_button_notch_clear`: a 10 mm finger cylinder approaching `btn_hi` along the face normal does not intersect the dock.
  - `test_no_trapped_supports`: every downward-facing internal surface of `plenum()` has an overhang of 45° or less, or is a bridge of 20 mm or less. Implement this as `assert()`s on the plenum's construction parameters, not as a mesh analysis.

- [ ] **Step 2: Run the tests and confirm they fail**

- [ ] **Step 3: Implement the plenum, duct, exhaust chamber, grille, notch and groove**

- [ ] **Step 4: Run the tests and confirm they pass**

  Also run `make previews` to produce a cross-section PNG at X = 0 and each X vent position: `previews/section-<size>.png`. Visually confirm the path runs fan → plenum → intake duct → Pager → exhaust → room.

- [ ] **Step 5: Commit**

  Commit: `feat: sealed plenum, intake duct and isolated exhaust`

---

### Task 5: Cable management, fit coupon, TPU gasket

**Files:**
- Modify: `src/body.scad`, `src/dock.scad`, `tests/check.py`

**Interfaces:**
- Produces:
  - `fan_cable_channel()`: about 7 mm wide, running from both lower corners of the slot to a rear exit with a strain-relief zig-zag (2 bends). It is open to the top along its whole length, works with the fan in either orientation, and has a pocket for an inline adapter of 15 × 10 × 30 mm.
  - `pager_cable_guide()`: a 10 mm wide U-channel running down from the port window to the base edge.
  - `coupon()`: the dock intersected with a slab 8 mm thick, perpendicular to the face normal, at the seat rim. It includes the intake-duct rim and the pocket outline.
  - `gasket()`: a TPU lip shaped to fit `gasket_groove()`, 1.0 mm wall and 2.0 mm tall.

- [ ] **Step 1: Write the failing tests**
  - `test_cable_channel_open_top`: a 7 × 7 mm box projected straight up from every channel segment, from the channel floor to Z = H + 1, does not intersect the dock.
  - `test_adapter_pocket`: a 15 × 10 × 30 mm box at the pocket does not intersect the dock.
  - `test_coupon_small`: the `coupon()` bbox fits within 256, its thickness along the face normal is ≤ 10 mm, and the output is not empty.
  - `test_gasket_fits_groove`: `gasket()` is not empty, and `intersection(dock(), gasket_seated())` is empty.

- [ ] **Step 2: Run the tests and confirm they fail**

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run the tests and confirm they pass**

- [ ] **Step 5: Commit**

  Commit: `feat: cable management, fit coupon and tpu gasket`

---

### Task 6: Export, previews, README

**Files:**
- Modify: `Makefile`, `README.md`
- Create: `stl/dock-80.stl`, `stl/dock-92.stl`, `stl/dock-120.stl`, `stl/coupon-{80,92,120}.stl`, `stl/gasket-{80,92,120}.stl`, `previews/*.png`

- [ ] **Step 1: Add the `stl` and `previews` make targets**

  The `stl` target renders each `part` × `fan_size` with `$fn = 64`. The `previews` target renders iso and section PNGs per variant, with the posed Pager and fan shown as `%` ghosts.

- [ ] **Step 2: Build everything and run the tests**

  Run: `make test stl previews`

  Expected:
  - all tests pass;
  - 9 STLs;
  - each dock STL bbox is ≤ 256.

- [ ] **Step 3: Write the README**

  Cover:
  - what the dock is;
  - variants;
  - `make` usage;
  - print settings: PLA Matte, print on the base with no supports, 3 or more walls, and TPU on an external spool for the gasket;
  - the caliper-verify list (the `VERIFY BY CALIPER` params);
  - the test protocol from the spec;
  - Hak5 CC BY-NC attribution.

- [ ] **Step 4: Confirm the LFS rules caught the new STLs, then commit**

  Run: `git lfs ls-files`

  Expected: the 9 new STLs plus the 2 reference files.

  Commit: `feat: export 80/92/120 variants, previews and readme`

- [ ] **Step 5: Hand off to the user for review**

  Show the user the preview PNGs. Ask them to caliper-check the `VERIFY BY CALIPER` values and print the 80 mm coupon first.
