// Noctua fan envelope and its pose in the rear tray.
// Fan frame: centred in X/Y, z = 0 inner face, z = fan_t outer face.

function rear_t() = [0, -cos(seat_angle), sin(seat_angle)];  // up the rear slope
function rear_n() = [0, sin(seat_angle), cos(seat_angle)];   // out of the rear face

module fan_envelope(t = fan_t) {
    translate([-fan_size/2, -fan_size/2, 0]) cube([fan_size, fan_size, t]);
    // cable strain-relief bump on one edge, near a corner
    translate([fan_size/2 - 6 - fan_nub[0], fan_size/2 - 0.01, (t - fan_nub[2])/2])
        cube([fan_nub[0], fan_nub[1], min(fan_nub[2], t)]);
}

// Origin on the fan's inner face centre; outer face flush with the rear face.
module fan_pose() {
    vc = fan_v0 + fan_tray/2;
    p = [0, D, 0] + vc * rear_t() - fan_t * rear_n();
    multmatrix([[1, 0, 0, p[0]],
                [0, rear_t()[1], rear_n()[1], p[1]],
                [0, rear_t()[2], rear_n()[2], p[2]],
                [0, 0, 0, 1]]) children();
}
