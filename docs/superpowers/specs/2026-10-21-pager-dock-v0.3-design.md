# Pineapple Pager desk cooling dock v0.3: design

Date: 2026-10-21
Builds on: v0.2.2 (tag), spec `2026-10-19-pager-dock-v0.2-design.md`. Anything
this document doesn't change carries over from v0.2.
Printer / material: Bambu P1S, Bambu PLA Matte, supports OFF, standing on its base.

## Why v0.3

Findings from the first printed v0.2 dock (40x10, user-tested):

- **It printed great and works pretty well.** The seat, the slot, the air path and
  the drop-in fan are all keepers.
- **The fan slot's depth is wrong both ways.** The 40x10 slot is 14.3 mm deep
  (fan 10 + filter stack 3.8 + 0.5 slack). Without a filter the fan sinks 4 mm
  past its land and rocks. With the two printed frames the stack binds at the
  fan-width part of the slot: the grid frame's pegs stand 0.4 mm proud of the cap
  when the frames are empty, and printed parts eat the remaining 0.3 mm. Even
  de-nubbed and empty it takes technique to get in, and there is no way media
  would fit in the sandwich. One frame alone still leaves the fan 2.7 mm loose.
- **Root cause:** the filter shares the fan's pocket, so the fan's seal depends on
  whatever is stacked behind it. The "empty frames as spacer" idea doesn't work
  in practice.
- The filter is a set-and-forget part: once loaded it stays for 3 to 4 months.

## Intent (user's words, paraphrased closely)

Fix the fan seat so the fan sits snug with and without the filter. Spend the few
millimetres of housing depth that takes, and claw the filament back, plus some
style, from the two big flat areas the user looks at: the knife-edge front lip and
the flat top. Rounding the body's corners waits for a later, purely aesthetic
round. Cables (both the fan's and the Pager's) also wait for a later round.

## Goals

1. **The fan seats on its land in every configuration:** no filter, filter in,
   filter being swapped. Nothing behind the fan affects its fit.
2. **The filter stack, with media in it, slides in and out by hand** with no
   technique. Media replacement stays a seconds, no-tools job.
3. **A front edge that reads as designed, not as a blade:** the floating toe.
4. **A roof that slopes down toward the back**, as steep as each fan allows, so
   the dock reads as a ridge instead of a block and the fan is easier to reach.
5. Less filament than v0.2.2 for the same variant, or at worst the same. (The
   housing grows 3 to 4 mm; the toe and roof cuts should pay for it.)
6. All four variants (60x15, 60x25, 40x10, 40x20) get all three changes.
7. Prints as before: standing on its base, supports OFF, no bridge over
   `bridge_max`, no free-standing thin features.

## Non-goals

- No change to the seat: pocket, clearances, clip relief, intake duct, exhaust,
  end windows, button notch, gasket groove, gasket, fit gauge and coupon all stay.
- No change to the fan's pose (15° lean, position) or the air hole.
- No cable work. The fan cable keeps its lower-corner reliefs exiting out the
  back; the Pager's USB guide stays. The tunnel under the new toe is left plain
  (user decision: cables for another round).
- No corner rounding or edge softening (deferred to an aesthetics round).

## Anti-goals

- A fan fit that depends on a spacer, a filter, or any part the user might leave
  out.
- Tolerances so tight the parts need technique. The seal is the fan on its land;
  the filter seals nothing and should be loose.
- A roof so low that the back wall no longer holds the fan or the filter at the
  top, or that cuts into the air path or the seat's cuts.
- Supports, or an underside that needs them.

## Decided

### 1. The filter gets its own slot (user, from Claude's recommendation)

- **Fan slot depth = `fan_t` + `fan_clear_z`** (0.5 mm, as today). The fan drops in
  and the slot's rear wall holds it against the land, exactly as the fan alone
  would sit today if the slot were the right depth.
- **A thin divider wall** separates the fan slot from a second, parallel slot
  behind it. The divider carries the rear lips and the air window that the
  current slot's lips form: the lips bear on the fan's frame now, not on a filter.
  Divider thickness `div_t` = 1.6 mm *(Claude's call: three to four perimeters,
  vertical, nothing bears on it sideways; the builder may use `wall` = 2.4 if the
  slicer or a test argues for it, at 0.8 mm more depth)*.
- **The divider's air window is closed on all four sides** *(Claude's call, from
  the builder check)*: a square inside the frame's border, lip width `fan_lip` = 3
  on every side, not open to the top as today's lips are. Under suction the
  loose frame then seals on four sides against the divider's lips. Unfiltered
  paths that remain, accepted for this round: the slit between the fan's back
  and the divider (0 to `fan_clear_z` wide, fed from the open slot top), and the
  fan-cable corner reliefs, which run through the divider and the rear wall at
  the frames' lower corners and so bypass the media there (found in review; a
  sealed cable exit belongs to the cable round). Pushing `fan_clear_z` toward
  zero is not, see anti-goals.
- **Filter slot** behind the divider, open at the top like the fan slot, closed at
  the back by a rear wall with the same four-sided window so the filter's border
  bears on it (frame border `filter_border` = 4, as today).
  - Depth = `filter_stack` + `filter_clear_z`, with `filter_clear_z` = 0.8 mm
    *(Claude's call)*.
  - `filter_gap` goes from 0.6 to **1.2 mm** *(Claude's call: MERV 8 media is
    nearer 1 mm than 0.6, and the frames were already impossible to close on it)*.
    `filter_stack` = 2·`frame_t` + `filter_gap` = 4.4 mm.
  - Side clearance for the frames: **0.5 mm per side** (`filter_clear`), more than
    the fan's 0.3 because nothing seals on the frames. Whether that comes from a
    wider filter slot or from printing the frames smaller than `fan_size` is the
    builder's call; the frames' border must still land on both the divider's lips
    and the rear wall's lips with margin.
  - The finger scallops run through both slots, so either part can be pinched out.
  - The fan-cable corner reliefs continue straight through the divider and the
    filter slot and out the back, same cross-section, with their 45° roofs. The
    frames' corners pass over that void, as they do today over the relief.
- **Net housing growth:** about `div_t` + `filter_stack` + `filter_clear_z` −
  (old stack 3.8) ≈ 3.0 mm at `div_t` 1.6, the same for every fan size.
- **Pegs:** the empty-frames-as-spacer use is retired, so the frames no longer
  need to close flat when empty. Peg height stays `frame_t` + `filter_gap` − 0.2,
  which puts the peg tips 0.2 mm below the cap face with media of the gap's
  thickness. The filter slot's 0.8 mm slack absorbs thinner media (pegs then stand
  proud by the difference). `peg_fit` stays as is.
- **Pull mode:** unchanged, filter left out; the filter slot is simply empty.
- **README:** the filter section changes to "slide the stack into the slot behind
  the fan, grid toward the fan"; the "snap the empty frames together as a spacer"
  step is removed; media square sizes follow whatever the frames end up being.

### 2. Floating toe (user, chose B of three mockups)

- Remove everything in front of a 45° plane that rises from the desk toward the
  front, starting `toe` = 24 mm behind the current front-bottom edge *(Claude's
  call on the number)*. The front edge becomes a horizontal 90° edge 12 mm above
  the desk and 12 mm forward of the new contact line; the underside is a 45°
  overhang, printable standing on the base; the footprint is 24 mm shorter.
- Plain underside: no groove, no cable feature.
- Nothing else moves: the seat and the air path are well behind the cut (the
  nearest cavity, the intake duct's bottom, is around 50 mm back and 10 mm up).
  The coupon and fit gauge are unaffected (the coupon's box starts above the toe).
- The user saw this on a schematic; the exact edge height and depth are theirs to
  tune after a print (`-D toe=`).

### 3. Roof sloping down toward the back (user, chose A of three mockups)

- Today the top is a flat horizontal shelf at the seat's full height, 38 mm deep
  (the seat slab's top edge hulled with the fan housing). On the 40 mm docks the
  fan sits 43 mm below it at the bottom of a well.
- **One straight plane, full width,** from the crest (the top edge of the 45°
  front face, where it meets the flat top today) down toward the back, cutting
  the body after the hull. It stops **`roof_keep` = 4 mm above the fan slot's
  top rear corner** *(Claude's call)*, measured up the fan plane: the plane passes
  through the crest and through the housing's rear-top edge raised by `roof_keep`
  along `fan_u()`. Each variant gets the angle that gives it:

  | Variant | On v0.2.2's housing | With the housing 3 mm deeper (expected) |
  |---|---|---|
  | 40x10 | 45° | 43° |
  | 40x20 | 37° | 35° |
  | 60x15 | 25° | 22° |
  | 60x25 | 17° | 15° |

  (Checked against the live model by the builder check; "the fan slot's top rear
  corner" means the housing box's rear-top edge, `fan_size`/2 + `fan_clear` up
  the fan plane at the housing's full depth.)

  `roof_angle` may also be forced with `-D`; clamp at 0° (never rising).
- The roof truncates the slot well, the scallops and the lips above the fan; it
  must keep at least `wall` of material over the exhaust chamber, the button
  notch, the gasket groove and the air chamber. At 45° the roof is nearly
  perpendicular to the front face through the crest, so the `wall` the notch and
  exhaust already keep below the crest carries over (the builder check measured
  the button notch as the tightest at about 3.1 mm on 40x10); the builder proves
  it with the existing grown-cut test pattern.
- The back face below the roof stays as the hull makes it.

## Carried over from v0.2.2 (unchanged unless the new shape forces it)
- Fan pose, teardrop hole, land and ledge, side clearance `fan_clear` 0.3, cable
  reliefs with 45° roofs, finger scallops.
- Chamber, intake duct, exhaust chamber and bar grille, button notch, gasket.
- Seat coupon, fit gauge, gasket STLs: one of each. The coupon's box reaches 3 mm
  past the crest, where the roof would now chamfer it; clip the box at the crest
  so the coupon stays as printed.
- Fan gauge: still the bottom of the slot, built from the same housing and slot
  modules, so it picks up the divider and filter slot automatically. **It becomes
  one per variant** (`stl/fan-gauge-{60x15,60x25,40x10,40x20}.stl`) instead of one
  per size *(Claude's call, from the builder check: the slot is now exactly
  `fan_t` + 0.5 deep, so a gauge cut for the thick fan would give the thin one the
  very slop v0.3 removes; the gauge must prove depth, not just width)*. Makefile
  `GAUGE_T_*`, `test_fan_gauge` and the README's "a thin fan will tip in it" note
  change to match.
- Makefile targets and names, test harness in `tests/check.py`, previews, LFS
  for STLs and PNGs.

## Housekeeping *(Claude's calls)*
- Parameters, all in `src/params.scad`, all `-D`-overridable: `div_t`,
  `filter_clear`, `filter_clear_z`, `filter_gap` (new value), `toe`, `roof_keep`,
  `roof_angle` (derived unless forced).
- Tests: retire `test_stack_retained` and `test_spacer_slack` as written. Add or
  rewrite: fan alone seats on the land with exactly `fan_clear_z` slack; filter
  stack (frames with a `filter_gap`-thick media proxy) fits its slot with the
  stated clearances and nothing else in the filter slot's way; the toe's lowest
  front point and the 45° underside; the roof keeps `roof_keep` above the slot's
  rear-top corner and `wall` over every cavity; the bridge/ceiling test still
  passes.
- Add `.superpowers/` to `.gitignore` (the brainstorm mockups live there).
- Version: v0.3.0 when printed and approved, following the existing tag and
  release flow (Gitea `origin`, GitHub `public`). The user decides when.

## Deliverables
- `stl/dock-{60x15,60x25,40x10,40x20}.stl`, `stl/filter-grid-{40,60}.stl`,
  `stl/filter-cap-{40,60}.stl` regenerated; `stl/fan-gauge-{60x15,60x25,40x10,40x20}.stl`
  replace the two per-size gauges; coupon, gasket and fit gauge unchanged.
- Previews per variant (front, rear, section).
- README updated: filter install, printing notes (toe underside, roof), the gauge
  note, and the filament figure once the user reslices.

## How we judge it
- Fan gauge (its own variant) and full dock: the fan drops in and seats firm on
  its land, no rocking, with the filter slot empty.
- Filter: a loaded stack slides in and out of its slot by hand; the fan does not
  move when it does.
- Slicer: the 40x10 uses no more filament than v0.2.2's 40x10.
- Print: toe underside and roof print clean with supports off.
- Thermal and noise as v0.2 (unchanged air path; a quick FLIR check is enough).

## Left to the builder
- How the filter slot and divider are formed in `slot_local()` / the housing box.
  Prefer widening the slot over shrinking the frames, so the 40 mm frames the
  user already printed still fit.
- Exact implementation of the toe and roof cuts (half-spaces after the hull).
- Whether the back face needs re-hulling after the roof cut for a clean look.
- Test details, preview tweaks, README wording.
