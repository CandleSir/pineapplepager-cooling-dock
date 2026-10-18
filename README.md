# pinepager-desk-cooling-dock

A one-piece, 3D-printable desk dock for the Hak5 WiFi Pineapple Pager. It
holds the Pager face-up at 45° and uses a Noctua fan to push (or pull) air
*through* the Pager's own vents. It's built for long, plugged-in homelab
sessions.

Air path:

1. Air enters through the fan tray on the rear slope.
2. It fills a sealed chamber inside the dock.
3. An intake duct carries it to the two grilles on the Pager's lower (button)
   edge, and it passes through the Pager.
4. It leaves through the upper-edge grille, under the bar grille, and through
   the end vent's open side window.

Flip the fan over to run the same path under negative pressure.

![front](previews/front-92.png) ![rear](previews/rear-92.png)
![section through the right-hand grille: fan blue, pager red](previews/section-92.png)

## Variants

| Fan | Width × depth × height (mm) | File |
|---|---|---|
| 80 mm | 102 × 193 × 88 | `stl/dock-80.stl` |
| 92 mm | 114 × 210 × 97 | `stl/dock-92.stl` |
| 120 mm | 142 × 249 × 117 | `stl/dock-120.stl` |

Each variant also has `stl/coupon-<size>.stl`, the seat cradle on its own for
a cheap fit test, and `stl/gasket-<size>.stl`, an optional TPU seal strip.

## Using it

- **Pager:** drop it in face up. The belt clip can stay on or come off;
  both seat correctly. To lift it out, pinch either short end through the
  open side windows.
- **USB ports:** the port end is fully open, so fat plugs and thumb drives
  fit. Grooves on that side face guide the cables down to the desk.
- **Fan:** any standard Noctua 80/92/120 frame, 25 mm thick (15 mm slim
  frames also fit). It drops into the rear tray from above and rests on an
  inner ledge, held by gravity. No screws.
  - Turn it so its cable leaves at a lower corner, then lay the cable into
    the open channel down the rear face. There is a pocket in the channel
    for an inline adapter of up to 30 × 15 × 10 mm.
  - There is no built-in finger guard, because one would block the drop-in.
    Screw a Noctua fan grill (for example NA-FG1) onto the fan if you want
    one.
- **Optional gasket:** press the TPU strip into the groove in the seat's
  lower wall. It seals the one leak path, from the intake duct up the
  Pager's lower edge to the face.

## Printing (Bambu P1S, Bambu PLA Matte)

- **Dock:**
  - Print it standing on its base, as exported.
  - **Supports OFF.** The inside is a sealed chamber, so any support the
    slicer puts in there can never be removed. Every internal down-facing
    surface is a 45° overhang or a bridge of 18 mm or less.
  - Use 3 or more walls. Infill to taste; it's mostly hollow.
- **Coupon:** prints face up, flat. Print it first to check the fit and the
  vent alignment before printing the full dock.
- **Gasket:** TPU from the external spool, flat, 100% infill.

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
openscad -D fan_size=92 -D pg_T=24.8 -D 'part="dock"' -o dock.stl src/dock.scad
```

## Building

Requires OpenSCAD (2021.01 is fine) and Python 3.

```sh
make test       # geometry tests: fit, clearances, air path, leaks, cables
make stl        # stl/{dock,coupon,gasket}-{80,92,120}.stl
make previews   # previews/{front,rear,section}-{80,92,120}.png
```

## Testing the cooling

Run the same sustained load for the same time in each of these setups:
- undocked;
- docked with the fan off;
- docked with the fan on, pushing;
- docked with the fan on, pulling.

Compare the Pager's temperature over SSH (`cat /sys/class/thermal/thermal_zone*/temp`).
For a quick airflow check, hold a tissue strip over the upper grille.

## Credits

The Pager reference geometry (`hak5-wifi-pineapple-pager.stl` / `.step`) is
Hak5's *Pineapple Pager Reference Model*, published on Printables under
CC BY-NC 4.0. The dock is a non-commercial derivative.
