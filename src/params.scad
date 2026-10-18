// All numbers live here. Override any of them with `openscad -D name=value`.
//
// Pager values are in the Hak5 reference STL frame: X = long axis,
// Y = short axis (-Y = button edge), +Z = face, origin at body centre.
// Measured from hak5-wifi-pineapple-pager.stl; values marked
// VERIFY BY CALIPER should be checked against the real device.

// ---- Pager body
pg_L = 87.0;          // VERIFY BY CALIPER  long side
pg_W = 61.92;         // VERIFY BY CALIPER  short side
pg_T = 24.5;          // VERIFY BY CALIPER  thickness, without clip or buttons
pg_zc = 0.0;          // STL Z of body mid-plane
pg_r = 7.0;           // plan-view corner radius (measured: fits <= 7)
pg_btn_h = 1.5;       // face buttons, proud of face
pg_clip_t = 9.38;     // VERIFY BY CALIPER  belt clip depth below the back

// Bounding boxes [[min],[max]] of the parts outside the rounded body.
pg_clip_box = [[-43.6, -11.6, pg_zc - pg_T/2 - pg_clip_t], [32.5, 11.6, pg_zc - pg_T/2]];
pg_face_btns = [[-34.8, -23.1, pg_zc + pg_T/2], [36.6, -9.9, pg_zc + pg_T/2 + pg_btn_h]];
pg_side_btn = [[-24.9, pg_W/2 - 0.5, -1.8], [-16.5, 31.55, 2.6]];  // VERIFY BY CALIPER (+Y edge)

// ---- Vents / ports, [x0, x1, z0, z1] (or [y0, y1, z0, z1] on the ends)
vent_lo = [[-25.0, -5.0, -5.2, 7.4], [5.0, 25.0, -5.2, 7.4]];  // VERIFY BY CALIPER  -Y edge grilles
vent_hi = [5.0, 25.0, -5.2, 7.4];                              // VERIFY BY CALIPER  +Y edge grille
btn_hi = [-24.8, -16.6, -1.7, 2.5];                            // VERIFY BY CALIPER  +Y side button
vent_end = [-21.7, 21.7, -9.5, 7.4];                           // VERIFY BY CALIPER  +X end vent
port_end_sign = -1;   // VERIFY  USB-C + USB-A are on the -X end

// ---- Envelope / fit
env_grow = 0.3;       // envelope grows this much past measured geometry

// ---- Seat placement
seat_angle = 45;      // degrees from horizontal
seat_u0 = 35;         // slope distance from the dock's front-bottom edge to the pager's -Y edge
seat_depth = 22;      // pocket depth below the front face (covers vent tops)
lip_z = 4;            // nothing of the seated pager may sit lower than this

// ---- Fan
fan_size = 120;       // 80 | 92 | 120
fan_t = 25;
fan_hole = fan_size == 80 ? 71.5 : fan_size == 92 ? 82.5 : 105;  // reference only

// ---- General
wall = 2.4;
$fn = 48;
