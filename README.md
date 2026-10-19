# pinepager-desk-cooling-dock

A one-piece, 3D-printable desk dock for the Hak5 WiFi Pineapple Pager. It
holds the Pager face-up at 45° and uses a small Noctua fan to push (or pull)
air *through* the Pager's own vents. It's built for long, plugged-in homelab
sessions.

Air path:

1. The fan stands upright at the back, facing back and tilted up 15°, with an
   optional dust filter on its outer face.
2. Air goes through a teardrop hole in the wall in front of the fan, into a
   short chamber under the seat.
3. The chamber feeds an intake duct at the two grilles on the Pager's lower
   (button) edge, and the air passes through the Pager.
4. It leaves through the upper-edge grille, under the bar grille, and through
   the end vent's open side window.

Flip the fan over to run the same path under negative pressure.

![front](previews/front-60x25.png) ![rear](previews/rear-60x25.png)
![section through the right-hand grille: fan blue, pager red](previews/section-60x25.png)

## Variants

One per fan. All are 5 V USB Noctuas:

| Fan | Width × depth × height (mm) | File |
|---|---|---|
| NF-A6x15 (60 × 15) | 101 × 147 × 92 | `stl/dock-60x15.stl` |
| NF-A6x25 (60 × 25) | 101 × 156 × 92 | `stl/dock-60x25.stl` |
| NF-A4x10 (40 × 10) | 101 × 142 × 92 | `stl/dock-40x10.stl` |
| NF-A4x20 (40 × 20) | 101 × 151 × 92 | `stl/dock-40x20.stl` |

The 80, 92 and 120 mm versions are in the `v0.1.0` tag.

Other parts:

| File | What it's for |
|---|---|
| `stl/filter-grid-{40,60}.stl`, `stl/filter-cap-{40,60}.stl` | Filter frames, one pair per fan size |
| `stl/fan-gauge-{40,60}.stl` | The bottom of the fan slot, for checking the fan's fit before a full dock |
| `stl/fit-gauge.stl` | A collar with the seat pocket's walls, for checking the Pager's fit |
| `stl/coupon.stl` | The full seat cradle on its own |
| `stl/gasket.stl` | Optional TPU seal strip for the seat's lower wall |

## Using it

- **Pager:** drop it in face up. The belt clip can stay on or come off; both
  seat correctly. To lift it out, pinch either short end through the open side
  windows.
- **USB ports:** the port end is fully open, so fat plugs and thumb drives fit.
  Grooves on that side face guide the cables down to the desk.
- **Fan:** it drops into the slot from above, so it sits upright against the
  wall with the air hole. Gravity leans it onto that wall, which seals it.
  - No screws are needed.
  - Turn it so its cable leaves from the bottom edge, at a lower corner. The
    cable goes straight out the back there, at desk level. An inline adapter
    just lies on the desk behind the dock.
  - To lift it out, pinch its top edge through the finger scallops on either
    side of the slot.
  - Flip the fan over for pull mode, and its cable comes out of the other lower
    corner.

## Dust filter (push mode)

In push mode, every bit of air reaching the Pager comes through the fan first.
A filter on the fan's outer face therefore cleans all of it, and the dust ends
up on a square you replace instead of inside the Pager. The filter is two thin
frames with a square of MERV 8 furnace-filter media between them.

1. **Cut the media.** Cut a pleated panel out of a MERV 8 furnace filter and pull
   it flat. Cut squares from the flat stretches between folds:
   - 39 mm for the 40 mm fans;
   - 59 mm for the 60 mm fans.

   If the thin backing mesh peels off easily, remove it. If not, keep it and put
   it on the fan side.
2. **Load it.** Snip a small triangle off each corner of the square, so the
   pegs don't tear it. Lay it on the grid frame between the four corner pegs,
   then press the cap down onto the pegs. The pegs are a press fit into the
   cap's holes, so the stack holds together in your hand. If it's too tight to
   press on, reprint the cap with `-D peg_fit=0.15`.
3. **Install it.** With the fan in place, slide the filter stack down the back
   of the slot, between the fan and the lips, with the grid facing the fan. The
   lips hold it all in place. To lift the fan or the filter out, pinch its top
   edge through the finger scallops on either side of the slot.
4. **Without a filter**, snap the two frames together empty and use them as a
   spacer, so the fan can't walk off its wall.
5. **In pull mode**, leave the filter out; it would be on the exhaust side.

Replace the media every few months, or when it looks grey. The grid also works
as a finger guard in push mode.

## Printing (Bambu P1S, Bambu PLA Matte)

- **Dock:**
  - Print it standing on its base, as exported.
  - **Supports OFF.** The chamber inside is closed, so any support printed in
    there can never come out. Every internal overhang is 45° or steeper, and no
    bridge is longer than 25 mm. Bambu Studio may still flag the short bridges;
    they print fine.
  - **Infill: about 10 %.** Only the air path is modelled hollow. The rest of
    the body behind the seat is solid in the model and prints as sparse infill,
    so a low infill keeps the filament down. Use 3 or more walls.
- **Filter frames:** print flat, grid side down.
- **Fan gauge:** prints upright, as exported. Drop the fan in. It should slide
  down without forcing and sit flat against the wall without rocking.
- **Seat checks:**
  - `fit-gauge.stl` prints flat. Slide it onto the Pager to the middle of its
    edge, with the bump over the side button.
  - `coupon.stl` prints face up, flat.
- **Gasket:** TPU from the external spool, flat, 100 % infill.

## Check with calipers before the full print

The Pager dimensions come from Hak5's reference model. Every value marked
`VERIFY BY CALIPER` in `src/params.scad` should be confirmed on the real
device:
- body length, width and thickness;
- clip depth;
- the two lower-edge grilles, the upper-edge grille, the side button and the
  end vent;
- which end carries the USB ports (`port_end_sign`, currently the −X end)
  and where the ports are.

Override any value without editing files:

```sh
openscad -D fan_size=60 -D fan_t=25 -D fan_clear=0.35 -D 'part="dock"' -o dock.stl src/dock.scad
```

## Building

Requires OpenSCAD (2021.01 is fine) and Python 3.

```sh
make test       # geometry tests: fit, clearances, air path, leaks, bridges
make stl        # every part in stl/
make previews   # previews/{front,rear,section}-<variant>.png
```

## Testing the cooling

Run the same sustained load for the same time in each of these setups:
- undocked;
- docked with the fan off;
- docked with the fan on, pushing, with and without the filter;
- docked with the fan on, pulling.

Compare the Pager's temperature over SSH (`cat /sys/class/thermal/thermal_zone*/temp`)
or with a thermal camera. For a quick airflow check, hold a tissue strip over
the upper grille.

## Credits

The Pager reference geometry (`hak5-wifi-pineapple-pager.stl` / `.step`) is
Hak5's *Pineapple Pager Reference Model*, published on Printables under
CC BY-NC 4.0. The dock is a non-commercial derivative.
