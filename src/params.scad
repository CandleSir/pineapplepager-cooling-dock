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
port_centres = [[-11.4, 0.45], [12.0, 1.1]];                  // VERIFY BY CALIPER  [y, z] of the two ports

// ---- Envelope / fit
env_grow = 0.1;       // envelope grows this much past the reference mesh (coupon 1 confirmed
                      // the real outline matches it; must stay < seat_clear_top)

// ---- Seat placement
seat_angle = 45;      // degrees from horizontal
seat_u0 = 47;         // slope distance from the dock's front-bottom edge to the pager's -Y edge
seat_depth = 24;      // pocket depth below the front face (covers vent tops + gasket groove)
lip_z = 4;            // nothing of the seated pager may sit lower than this

// ---- Fan (5 V USB Noctua): 60x15, 60x25, 40x10, 40x20
fan_size = 60;        // 40 | 60
fan_t = 25;           // 10 | 15 | 20 | 25
fan_tilt = 15;        // degrees back from vertical: faces back and up, top leaning forward

// ---- General
wall = 2.4;
$fn = 48;

// ---- Derived body geometry (dock frame: X across, -Y toward user, Z up)
fan_clear = 0.3;      // per side, fan in its slot
fan_clear_z = 0.5;    // slack front-to-back, fan + filter stack between land and lips
fan_ledge = 3;        // land around the air hole that the fan frame seals against
fan_lip = 3;          // rear lips hold the filter stack in the slot
fan_nub = [8, 4, 6];  // cable strain-relief bump on the frame edge [along, out, thick]
seat_clear = 0.5;     // per side, pager in its pocket (ends and the -Y seal wall)
seat_clear_top = 0.15;  // +Y wall only: gravity seats the pager on the -Y wall, so all
                        // the play gathered here (coupon 1 rattled ~1 mm); 0.15 takes it out
clip_relief = 1.0;    // extra room around the belt clip
win_inset = 3;         // end windows stop this far short of the long edges
side_margin = 4;
exh_w = 6;            // exhaust slot beyond the pager's +Y edge (along the slope)
notch_len = 18;       // side-button finger notch, beyond the pager's +Y edge
notch_w = 20;
seat_u_top = seat_u0 + pg_W + seat_clear + max(exh_w, notch_len) + wall;
H = seat_u_top * sin(seat_angle);   // the seat sets the height now
Wd = pg_L + 2*seat_clear + 2*wall + 2*side_margin;
slab_d = seat_depth + seat_clear + wall;  // seat slab, face to its back

// ---- Fan slot and filter
frame_t = 1.6;        // each filter frame
filter_gap = 0.6;     // MERV 8 media clamped between the frames
filter_border = 4;    // frame border, wider than fan_lip so the lips bear on it
grid_bar = 1.2;       // fan-side grid keeps the media out of the blades
grid_pitch = 8;       // (8 - 1.2)^2 / 8^2 -> 72 % open
peg_d = 2;            // corner pegs on the grid frame...
peg_fit = 0.2;        // ...into cap holes this much bigger
filter_stack = 2*frame_t + filter_gap;
slot_depth = fan_t + filter_stack + fan_clear_z;
hole_r = fan_size/2 - fan_ledge;
relief = fan_clear + fan_nub[1] + 0.5;  // cable-bump room beyond the frame at the lower corners
hx = fan_size/2 + relief + wall;        // housing half-width (and depth below the fan centre)

// ---- Air path
duct_w = 5;           // intake duct reaches this far beyond the pager's -Y edge
duct_dip = 6;         // ...and this far below the seat floor slab, into the chamber
vent_margin = 1.5;    // duct / exhaust openings overlap each grille by this much
duct_top_margin = 0.5;  // ...except above the lower grilles, leaving room for the groove
grille_bar = 1.6;     // exhaust bar grille: 1.6 / (1.6 + 3.8) solid -> 70 % open
grille_gap = 3.8;
grille_t = 1.6;
grille_rim = 1.2;     // strip along the pocket edge that anchors the bars' lower ends
groove_w = 1.2;       // optional TPU gasket groove in the pocket's -Y wall
groove_d = 1.0;
// pager-frame Z of the dock's front face, and of the gasket groove's lower edge
face_z = pg_zc - pg_T/2 + seat_depth;
groove_z = vent_lo[0][3] + duct_top_margin + 1.3;

// ---- Cables
guide_w = 10;         // pager USB cable guide groove on the port-end side face
guide_d = 5;

// ---- Fit coupon: the seat cradle (face down to the floor), printed face-up
cradle_t = seat_depth + seat_clear + wall;
gauge_h = 8;          // fit gauge: a collar of the pocket outline, slid onto the pager

// ---- Printing (standing on the base, supports OFF)
bridge_max = 25;      // longest span the slicer may bridge
rib_w = 1.2;          // designed-in supports: posts under the clip pocket's wall
                      // (two 0.45 mm lines + margin)
