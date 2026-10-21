// Noctua fan envelope and its pose in the upright rear slot.
// Fan frame: centred in X/Y, z = 0 inner face (on the land), z = fan_t outer face;
// y runs up the fan plane.

function fan_n() = [0, cos(fan_tilt), sin(fan_tilt)];   // out of the slot: back and up
function fan_u() = [0, -sin(fan_tilt), cos(fan_tilt)];  // up the fan plane (top leans forward)
function slab_in() = [0, sin(seat_angle), -cos(seat_angle)];  // into the body, behind the seat face

// Seat cuts the slot must clear (pager frame): pocket, exhaust, button notch, clip relief + wall.
function seat_cut_boxes() = let(c = seat_clear, back = pg_zc - pg_T/2,
                                cx = (btn_hi[0] + btn_hi[1])/2, g = clip_relief + wall) [
    [[-pg_L/2 - c, -pg_W/2 - c, back - c], [pg_L/2 + c, pg_W/2 + seat_clear_top, face_z]],
    [[vent_hi[0] - vent_margin, pg_W/2 - 1, back - c], [vent_hi[1] + vent_margin, pg_W/2 + c + exh_w, face_z]],
    [[cx - notch_w/2, pg_W/2 - 1, btn_hi[2] - 3], [cx + notch_w/2, pg_W/2 + c + notch_len, face_z]],
    [pg_clip_box[0] - [g, g, g], pg_clip_box[1] + [g, g, g]]];
function seat_ext() = max([for (b = seat_cut_boxes()) for (k = box_corners(b)) pose_pt(k) * fan_n()]);

// The housing's lowest corner (y = -hx, z = -wall) sits on the desk. The fan goes as far
// forward as the seat cuts allow, and far enough back that its hole is under the seat slab.
function fan_z0() = hx * cos(fan_tilt) + wall * sin(fan_tilt);
function fan_y_clear(z) = (seat_ext() + wall + 0.5 - z * sin(fan_tilt)) / cos(fan_tilt);
function fan_y_hole(z) = (slab_d + 1 + z * cos(seat_angle)
                          - (hole_r + 1) * (fan_u() * slab_in()) + wall * (fan_n() * slab_in())) / sin(seat_angle);
function fan_origin() = let(z = fan_z0()) [0, max(fan_y_clear(z), fan_y_hole(z)), z];

function fan_m() = let(o = fan_origin(), u = fan_u(), n = fan_n())
    [[1, 0, 0, o[0]], [0, u[1], n[1], o[1]], [0, u[2], n[2], o[2]], [0, 0, 0, 1]];
function fan_pt(p) = let(q = fan_m() * [p[0], p[1], p[2], 1]) [q[0], q[1], q[2]];
module fan_pose() multmatrix(fan_m()) children();

// Housing box (fan frame) around the slot, lips and land.
housing_box = [[-hx, -hx, -wall], [hx, fan_size/2 + fan_clear, housing_depth + wall]];
function housing_corners() = [for (k = box_corners(housing_box)) fan_pt(k)];

module fan_envelope(t = fan_t) {
    translate([-fan_size/2, -fan_size/2, 0]) cube([fan_size, fan_size, t]);
    // cable strain-relief bump on the bottom edge, near the +x corner
    translate([fan_size/2 - 6 - fan_nub[0], -fan_size/2 - fan_nub[1] + 0.01, (t - fan_nub[2])/2])
        cube([fan_nub[0], fan_nub[1], min(fan_nub[2], t)]);
}
