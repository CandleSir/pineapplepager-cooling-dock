# Pineapple Pager desk cooling dock: design

Date: 2026-10-18
Printer / material: Bambu P1S, Bambu PLA Matte (TPU optional, gasket only)

## Intent

A desk base station for the Hak5 WiFi Pineapple Pager, used during long
at-home homelab sessions (experiments, self-directed labs, post-op analysis
and assessments). The Pager stays plugged in over USB and is mostly driven
over SSH, so it runs under sustained load for hours. **Active cooling is the
real job of the dock.** The screen and buttons are mostly aesthetic and fun
while docked, but are sometimes used directly, so they must stay visible and
reachable.

The dock holds the Pager face-up at ~45° toward the seated user, in a low,
clean, Elgato Stream Deck–like wedge body (somewhat larger than a Stream
Deck, to fit the fan). A Noctua fan drops into a slot on the rear and
pressurises (or evacuates) a ducted chamber that forces air *through* the
Pager's own vents — not just past it.

## Goals

1. Real through-flow cooling: fan → sealed internal duct → one set of Pager
   vents → through the Pager → out its other vents → to the room. Reversing
   the fan (negative pressure) must work along the same path.
2. Three fan variants from one parametric source: **80 mm, 92 mm, 120 mm**
   Noctua.
3. Single printed piece, no moving parts (optional TPU gasket excepted).
4. Pager drops in and lifts out with no scuffing: clearance fit, not friction.
5. Ports stay fully usable with arbitrary cables and thumb drives.
6. Clean cable exits for both the Pager's USB cable and the fan's USB cable.
7. Works with the belt clip **on or off** — user should not have to remember
   to remove it.

## Non-goals

- No lever/push-out mechanism in v1 (pinch-grip removal is being tried
  first; a lever is a possible later revision).
- No fan control electronics; fan is powered from a USB hub on the desk.
- Screen is not modelled and needs no cutout (it is effectively flush).

## Anti-goals (failure even if it "works")

- A fan that just spins: air leaking around the Pager instead of through it.
- Friction-fit seat that leaves scrape/slide marks on the Pager.
- Ports boxed in so only slim cables fit.
- Cluttered/hardware-store look, dangling fan cable.

## Pager reference

Source files in repo root: `hak5-wifi-pineapple-pager.stl` /
`.step` (Hak5 reference model, mm, CC BY-NC 4.0 — credit Hak5 in README).
The user has calipers and will measure if the model is off; all pager
dimensions must be parameters so caliper values can override them.

STL coordinates (as exported): X = long axis, Y = short axis, +Z = face
(buttons/screen), −Z = back (belt clip).

- Overall bbox incl. clip: 87.0 × 62.5 × 35.4 mm.
- Body: ~87 × 62.5 mm, ~24 mm thick, generously rounded corners/edges.
  Buttons stand ~1.5 mm proud of the face along the −Y long edge.
- Belt clip: on the back, adds ~10 mm below the body; spring clip with a
  separate mount. Hak5 also ships a smooth battery cover (no clip).
  Extra parts: `~/Downloads/hak5-pineapple-pager-reference-model-model_files/`
  (`hak5-pineapple-pager-clip*.stl`, `...battery-cover*.stl`).
- Vents/ports (per user, confirmed against renders):
  - **−Y long edge** (button edge): two slot grilles. → "lower edge" when
    docked.
  - **+Y long edge**: one slot grille plus a side button. → "upper edge".
  - **One short end**: USB-C and USB-A ports, no vent ("port end").
  - **Other short end**: a single vent ("vent end").
  - The reference model's vent and port features are shallow; exact
    positions must be confirmed from renders/STEP and by caliper.
- **Internal airflow (user tested):** air passes clearly through the Pager
  between every combination of vents. Whether it has its own internal fan
  is unknown: the user hears nothing at power-on, maybe a faint hum (could
  be coil whine), and a web search found no teardown or community answer.
  Hak5's spec lists no fan. The design proceeds on the assumption that it
  is passive. If an internal fan turns up, the user flips the dock fan to
  match its direction, and the dock needs no change.

## Docked orientation

Landscape, face up, tilted ~45° back from horizontal, buttons (−Y edge) at
the bottom nearest the user, +Y edge at the top toward the rear. Tilt angle
is a parameter (45° default).

## The dock — decided

### Body
- Single-piece wedge, Stream Deck–like proportions, footprint grows with fan
  size. Clean flat surfaces, softened edges, no visible fasteners.
- Must fit the P1S bed (256 × 256 × 256 mm) for the 120 mm variant.

### Seat (drop-in pocket)
- Pocket matches the Pager body outline with **~0.5 mm clearance per side**
  (parameter). Looser than friction fit, close enough for the duct seal.
- **Clip relief pocket** in the seat floor shaped to the belt clip + mount,
  so the Pager seats with the clip on. With the clip off the Pager rests on
  the floor around the relief. Both must work.
- Lower lip supports the Pager's −Y edge; no screen bezel over the face.
- Upper-edge side button gets a notch so it remains pressable.

### Airflow path (default orientation = positive pressure)
- Fan drops into a slot on the rear face, blowing into a **sealed plenum**
  in the space under the inclined seat.
- **Intake duct:** plenum opens directly onto the two −Y (lower edge)
  grilles. Open duct mouth sized to the grilles — no perforation on the
  inside, to minimise restriction. This is the one area that needs a seal:
  the duct rim meets the Pager's lower edge with the same small clearance.
- **Exhaust:** +Y upper-edge grille exits through an open **bar grille**
  (thin bars, ~70 % open area) on the dock — the "perforated section". The
  vent-end short-side vent exits through an open side window.
- Air runs bottom → top, assisting natural convection.
- Fan reversed = negative pressure along the same path, drawing room air in
  through the exhaust openings.
- Everything other than the intake duct must not connect to the plenum
  (the open port window, exhaust grilles, etc. vent to room, not to the
  plenum).

### Port end
- **Window-frame bezel:** the dock is only a frame around the port-end
  short side, leaving the whole end exposed so oversized plugs and thumb
  drives fit. This end has no vents, so an open window here does not leak
  plenum air.

### Removal
- **Pinch grip** via the open port-end window (and vent-end window if it
  helps): user grabs the Pager's short end(s) and lifts. No thumb divot in
  the lower edge (it would breach the intake seal). No moving parts.

### Fan placement and slot (user decision: fan tilted to match the seat)
- **Trapezoid side profile (user decision):** the front face slopes at
  45° toward the user and carries the Pager seat. The rear face slopes at
  45° the opposite way and carries the fan, with the fan's bottom edge
  furthest out toward the back (leaning in at the top, like an A-frame).
  The top is flat and so is the base. The plenum is the enclosed interior
  between the two slopes. The fan intake faces up and back, so the desk
  can't starve it.
- Both faces share one height H, which is set by the fan slope (fan size
  plus walls) and is the larger of the two. Approximate figures:

  | Fan | H | Base depth | Width |
  |---|---|---|---|
  | 120 mm | ~92 mm | ~190–200 mm | ~135–140 mm |
  | 80 mm | ~62 mm | about two-thirds of the 120 mm size | about two-thirds of the 120 mm size |

  All three variants fit the P1S's 256 mm³ build volume. With both slopes
  at 45° it prints on its base with no supports on the outer faces.
- On the 92 and 120 mm variants the front slope is taller than the Pager
  needs. The Pager sits low on the front face (lower lip near the desk).
  The front face above its upper edge carries the exhaust bar grille. That
  exhaust region is walled off inside, so the upper-edge grille vents to
  the room and not back into the plenum.
- Upright-fan and flat-under-base layouts were considered and rejected.
- Drop-in from above/behind into a slot whose walls capture the frame;
  no screws. Noctua standard frames: 80 × 80, 92 × 92, 120 × 120 mm;
  thickness 25 mm default, parameter for slim (14/15 mm) frames.
- Fan intake side (outside, rear) has a finger-safe guard/grille with
  high open area.
- **Reversing = physically flipping the fan in the slot** (USB 5 V
  Noctuas can't be reversed electrically). *Builder's call:* the slot is
  symmetric so the fan fits either way round, and the cable path works
  from either corner/face.
- **Fan cable:** *builder's call:* an open-topped channel/keyhole from
  the slot to a strain-relief exit at the rear, so the cable drops in
  from above and no plug (4-pin or USB-A) ever has to pass through a
  hole. Room inside the dock for a small inline adapter lump. Specific
  fan model numbers are not fixed.

### Pager USB cable
- Exits cleanly from the port-end window; dock provides a guide channel
  so the cable leaves the dock tidily rather than hanging off the seat.

### Optional TPU gasket
- A separate thin TPU lip that fits the intake-duct rim, printable on the
  P1S without AMS. Optional; the dock must cool without it. The dock rim
  should have a shallow groove/locating feature it can press into.

## Printability constraints
- Single piece, Bambu PLA Matte, standard 0.4 mm nozzle.
- Prefer an orientation needing minimal or no supports. The 45° seat is
  printable unsupported; design internal plenum roofs and duct transitions
  as ≤45° overhangs or short bridges so supports never land inside the
  sealed plenum (they can't be removed).
- Walls ≥ 2 mm (≥ 5 perimeters is fine for rigidity).

## Deliverables & repo
- Parametric OpenSCAD source; one parameter selects fan size (80/92/120).
- Exported STLs (or 3MFs) for all three variants.
- A small **fit-test coupon**: the seat outline + intake rim only, a few
  mm tall, to verify clearance and vent alignment cheaply before a full
  print. Expected iteration: user has test filament and expects
  prototypes.
- Git LFS tracking for `*.stl`, `*.3mf`, `*.step` set up before the first
  commit of any new binary; existing reference STL/STEP renormalised into
  LFS (no history rewrite).
- README: what it is, how to build variants, print settings, Hak5 CC BY-NC
  attribution for the reference model.

## How we judge it works (builder's call)
- Fit coupon: Pager drops in/out without scraping, intake rim lines up
  with the two lower-edge grilles.
- Airflow: tissue/smoke test shows flow exiting the upper-edge grille and
  vent-end window (not just leaking around the seat).
- Thermal: Pager temperature read over SSH (e.g. `/sys/class/thermal`)
  after a fixed sustained-load run, undocked vs docked fan-off vs docked
  fan-on, both fan orientations.

## Left to the builder
- Exact external styling and proportions within "Stream Deck–like wedge".
- Plenum geometry and duct transitions (as long as they stay sealed,
  printable and low-restriction).
- Bar grille pattern, window-frame widths, fan guard pattern.
- Clip relief shape (from the clip STLs) and fan-slot tolerances.
- Print orientation and slicer settings.
- Whether to model the seat by importing/offsetting the Pager STL or as a
  parametric rounded box (must remain caliper-overridable either way).
