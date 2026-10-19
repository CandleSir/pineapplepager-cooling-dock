# Pineapple Pager desk cooling dock v0.2: design

Date: 2026-10-19
Builds on: v0.1.0 (tag), spec `2026-10-18-pager-cooling-dock-design.md`. Anything
this document doesn't change carries over from that spec.
Printer / material: Bambu P1S, Bambu PLA Matte, supports OFF.

## Why v0.2

Findings from the first printed v0.1.0 dock (92 mm fan, user-tested):

- **Positive pressure works far better than needed.** After 20 minutes of active
  scanning plus database recording, the Pager's outside and the air just inside
  its vents sat at room temperature (FLIR). Very little air actually passes
  through the Pager, and that little is enough.
- **The fan is oversized.** In both push and pull, the user could feel air blasting
  out of the fan at the back. Even positive pressure was far more than the job
  needs.
- **Negative pressure didn't work.** Clearances weren't tight enough for it.
- **The fan-opening ribs printed badly.** They printed well for about a third of
  their height, then wobbled more and more as they grew. Slower XY moves would
  have saved them. The bridge on top of them printed fine.

## Intent (user's words, paraphrased closely)

Tighten tolerances where we can and drop the fan size, to get good temperatures
with lower fan noise, significantly less filament, and a form factor that's
easier to restyle later. Keep the Pager's cradle/seat. Tighten up the rear (fan
area), and shrink the interior chamber so the pressure has a more direct path to
the Pager, instead of having to equalize across a big chamber first. Parts
longevity is the point of the dock, and cleanliness counts as part of longevity.

## Goals

1. **Four fan variants, all printed and ready together**, so the user can test one
   after another without waiting on model edits. All are 5 V USB Noctuas the user
   already owns:

   | Variant | Fan |
   |---|---|
   | 60×15 | NF-A6x15 5V (60 × 60 × 15 mm) |
   | 60×25 | NF-A6x25 5V (60 × 60 × 25 mm) |
   | 40×10 | NF-A4x10 5V (40 × 40 × 10 mm) |
   | 40×20 | NF-A4x20 5V (40 × 40 × 20 mm) |

   The 80, 92 and 120 mm variants are retired; v0.1.0 keeps them.
2. Same cooling as v0.1.0 in push mode, with less noise and much less filament.
3. A dust filter on the fan intake, for push mode (see below).
4. Pull mode is still preferred (less desk dust drawn through), but push is
   acceptable. Not a hard requirement for v0.2. In pull mode the likely leak is
   the gap between the Pager's lower edge and the seat wall above the intake,
   which the optional TPU gasket targets; the user has no TPU, so it's untested.
   **User decision:** leave seat clearances alone until the fan and chamber
   changes are tested and assessed.
5. Prints with supports OFF, with no thin free-standing features that wobble.

## Non-goals

- No change to the seat: pocket, clearances (including the approved
  `seat_clear_top` 0.15), clip relief, lower lip, intake duct, end windows,
  button notch, gasket groove and optional gasket all stay as in v0.1.0.
- No aesthetic work on the front edge facing the user. That comes later.
- No fan electronics or speed control.

## Anti-goals

- Shrinking the chamber by adding solid material. Use a duct or thin walls. If
  the chosen method still adds material, note it so the user can drop infill.
- Free-standing thin features (like v0.1.0's ribs) that wobble while printing.
- A filter that chokes the small fans (no HEPA or MERV 13+ media).

## Decided

### Shape (user)
- **Front:** about the same as v0.1.0, with the Pager on the 45° front face.
- **Sides and back:** sweep cleanly behind the Pager and taper down to the fan at
  the rear, closer to the original Stream Deck comparison. The seat, not the fan,
  now sets the body's size.

### Fan (user, from Claude's recommendation)
- **Faces straight back, tilted up about 15°.** That points the noise away from
  the user, keeps the intake clear of the desk, and keeps it away from the
  Pager's warm exhaust at the top grille.
- **Mounts in a drop-in slot open at the top.** The fan slides down from above
  and gravity holds it, with no screws. A slot open at the top has no ceiling to
  bridge.
- **Tilt direction:** the fan's top leans toward the front, so gravity presses it
  onto the inner wall it seals against *(Claude's call: this is what makes a
  gravity slot seal)*.
- **Air hole behind the fan: teardrop shape**, round with a pointed top, printable
  without supports. **No ribs.**
- **The hole must stay inside the fan frame's footprint** and leave a sealing land
  for the frame to rest on *(Claude's call)*. A full teardrop point would poke
  above a 60 mm frame and open into the slot, which is open at the top, giving a
  leak path. Truncate the point to a short flat top no wider than `bridge_max`
  (25 mm), or shape the hole otherwise, as long as it stays printable and inside
  the land.
- **Reversing:** flip the fan in the slot, as in v0.1.0.

### Tolerances (user: tighten where we can)
- **Fan slot:** about 0.3 mm per side, down from 0.6 *(Claude's guess; the seat
  gauge suggests the printer holds it)*. Make it a parameter.
- **Fan-slot gauge:** a small printable test piece per fan size (40, 60) to check
  the slot fit before printing a full dock, like the seat fit gauge.
- **Cable bump relief:** relief only where the fan's cable actually exits,
  instead of v0.1.0's eight notches. Flipping the fan for pull mode moves the
  cable to the mirrored corner, so both lower corners get a relief
  *(Claude's call)*. Each relief opens only toward the cable path, not into the
  chamber.

### Chamber (user)
- Shrink the interior so the fan's pressure reaches the Pager's lower-edge intake
  directly.
- Preferred method *(Claude's call)*: the tapered outer shell follows the air path
  closely, from the fan's air hole down to the intake duct, so the inside of the
  body is the duct. Where the shape leaves a gap between shell and air path, use
  a thin-walled duct and leave the rest of the body hollow. If anything adds
  material, add the infill note to the README.
- The air path must stay sealed from all room-air cuts (end windows, exhaust,
  button notch, cable channels), as in v0.1.0.

### Dust filter (user, from Claude's recommendation)
- **Purpose:** in push mode every bit of air that reaches the Pager has passed
  through the fan, so a filter on the fan's intake cleans it all. Dust ends up on
  a replaceable square, not inside the Pager.
- **Media:** MERV 8 furnace filter media. The user has three 16×20×1 filters. The
  media is pleated and often has a thin backing mesh on one side. The user flattens
  panels between folds and cuts squares.
- **Frame:** two thin printed frames that snap together, with the media sandwiched
  between them. One frame design per fan size (40, 60). The fan-side frame has a
  thin grid so suction can't pull media into the blades. The grid also acts as a
  finger guard in push mode; the user's Noctua grills don't come in 40/60.
- **Clamp gap:** a parameter, starting around 0.6 mm. A little compression holds
  soft media better than an exact gap. Check it on a first print rather than with
  calipers.
- **Placement:** the frame drops into the same slot, on the fan's outer side (the
  intake side in push mode). With the filter left out, the fan still seats against
  the inner wall.
- **Pull mode:** the filter is left out; it would be on the exhaust side.
- Swapping media should take seconds without tools.
- **Slot depth = fan + filter stack + clearance** *(Claude's call)*. The filter
  frame seals against the fan frame, so air can't bypass the media through the
  open slot top. The stack traps the fan against its land. Push-mode thrust on a
  small fan is comparable to the gravity holding it at a 15° lean, so without a
  filter the fan-side grid frame goes in alone as a spacer.

## Carried over from v0.1.0 (unchanged unless the new shape forces it)
- Fan cable: an open channel from the slot to a tidy exit, plus the pocket for an
  inline adapter. Re-route it to fit the new back.
- Pager USB cable guide, end windows, pinch grip, bar grille exhaust, optional
  TPU gasket.
- Fit gauge (`stl/fit-gauge.stl`) stays valid because the seat doesn't change.
- Printing: standing on its base, supports OFF, every bridge ≤ `bridge_max`
  (25 mm), checked by `test_no_long_bridges`. The clip-wall posts stay unless the
  new chamber removes the need for them.
- All dimensions stay parameters overridable with `-D`. Same geometry test
  harness. Git LFS for STLs and PNGs.

## Housekeeping *(Claude's calls)*
- Cable relief positions come from Noctua's published drawings for the four
  fans, made a little generous; the fan gauge catches a wrong guess.
- Coupon and gasket depend only on the seat: keep one of each, not one per
  variant.
- Remove the 80/92/120 variants from the Makefile, tests and `stl/`; v0.1.0 keeps
  them. Replace v0.1-only tests (trapezoid profile, fan ledge, etc.) with tests
  for the new slot, chamber and filter.

## Deliverables
- `stl/dock-{60x15,60x25,40x10,40x20}.stl`
- `stl/filter-frame-{40,60}-{outer,inner}.stl` (names left to the builder)
- `stl/fan-gauge-{40,60}.stl`
- Previews per variant, and a README updated for the variants, the filter (how
  to cut and load the media) and printing.

## How we judge it
- Fan gauge: fan drops in and seats without rocking or forcing.
- Filter frame: media holds flat, snaps together and apart by hand.
- Full dock prints with supports off and nothing wobbles.
- Thermal (FLIR, the user's method): after 20 minutes of active load in push mode
  with the filter, the Pager stays near ambient, as v0.1.0 did. Also compare with
  and without the filter.
- Noise: noticeably quieter than v0.1.0's 92 mm fan at the desk.
- Filament: noticeably less than v0.1.0 in the slicer.
- Pull mode: test whether it now works. Nice to have.

## Left to the builder
- Exact outer curves of the taper, within "sides and back sweep cleanly behind,
  tapering to the fan".
- Exact 15° tilt, if printability or packaging argues for a nearby angle.
- Teardrop truncation details, slot and frame geometry, snap features.
- Duct cross-sections, as long as they stay sealed, printable and low-restriction.
- Cable channel routing on the new back.
