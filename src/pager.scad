// Pager reference, envelope and docked pose.

pg_ref_file = "../hak5-wifi-pineapple-pager.stl";

// Unit vectors of the front slope, dock frame (-Y toward the user, +Z up).
function slope_t() = [0, cos(seat_angle), sin(seat_angle)];   // up the slope
function slope_n() = [0, -sin(seat_angle), cos(seat_angle)];  // out of the face

// Pager back face, -Y edge, in the dock frame.
function seat_origin() = seat_u0 * slope_t() - seat_depth * slope_n();

function m_t(v) = [[1,0,0,v[0]], [0,1,0,v[1]], [0,0,1,v[2]], [0,0,0,1]];
function m_rx(a) = [[1,0,0,0], [0,cos(a),-sin(a),0], [0,sin(a),cos(a),0], [0,0,0,1]];

// STL frame -> dock frame.
function pose_m() = m_t(seat_origin()) * m_rx(seat_angle)
                  * m_t([0, pg_W/2, pg_T/2 - pg_zc]);
function pose_pt(p) = let(q = pose_m() * [p[0], p[1], p[2], 1]) [q[0], q[1], q[2]];
function pose_dir(d) = let(q = pose_m() * [d[0], d[1], d[2], 0]) [q[0], q[1], q[2]];

module pager_pose() multmatrix(pose_m()) children();

// Extra boxes outside the rounded body.
function pg_boxes(clip) = concat(clip ? [pg_clip_box] : [], [pg_face_btns, pg_side_btn]);
pg_env_boxes = pg_boxes(true);

function box_corners(b) = [for (x = [b[0][0], b[1][0]], y = [b[0][1], b[1][1]],
                                z = [b[0][2], b[1][2]]) [x, y, z]];
function pg_env_corners(clip) = concat(
    box_corners([[-pg_L/2, -pg_W/2, pg_zc - pg_T/2], [pg_L/2, pg_W/2, pg_zc + pg_T/2]]),
    [for (b = pg_boxes(clip)) each box_corners(b)]);

module pager_ref(clip = true) {
    if (clip) import(pg_ref_file);
    else intersection() {
        import(pg_ref_file);
        translate([-pg_L, -pg_W, pg_zc - pg_T/2 - 0.05]) cube([2*pg_L, 2*pg_W, pg_T + 10]);
    }
}

module rbox(size, r) {  // rounded in plan, centred
    linear_extrude(size[2], center = true)
        offset(r) square([size[0] - 2*r, size[1] - 2*r], center = true);
}

module gbox(b, g) translate(b[0] - [g, g, g]) cube(b[1] - b[0] + [2*g, 2*g, 2*g]);

// Conservative solid that contains the real pager (STL frame).
module pager_envelope(clip = true, g = env_grow) {
    translate([0, 0, pg_zc]) rbox([pg_L + 2*g, pg_W + 2*g, pg_T + 2*g], pg_r + g);
    for (b = pg_boxes(clip)) gbox(b, g);
}
