// Dock body.

module body_shell() {
    rotate([90, 0, 90]) linear_extrude(Wd, center = true)
        polygon([[0, 0], [D, 0], [D - run, H], [run, H]]);
}

// Tray the fan drops into from above/behind, open to the outside, with
// corner reliefs for the cable bump in any orientation and an inner ledge.
module fan_slot() {
    s = fan_size + 2*fan_clear;
    fan_pose() {
        // tray, open outward
        translate([-s/2, -s/2, -fan_clear]) cube([s, s, fan_t + fan_clear + 80]);
        // cable-bump reliefs on all four edges, both sides of each corner
        for (a = [0:90:270]) rotate([0, 0, a])
            for (sx = [-1, 1])
                translate([sx > 0 ? s/2 - 6 - fan_nub[0] - 1 : -s/2 + 5, s/2 - 0.01, -fan_clear])
                    cube([fan_nub[0] + 2, fan_nub[1] + fan_clear, fan_t + fan_clear + 80]);
        // air opening through the ledge
        translate([0, 0, -wall - fan_clear - 1])
            linear_extrude(wall + 1.01)
                offset(4) square(fan_size - 2*fan_ledge - 8, center = true);
    }
}

// Pager-frame prism: footprint `b` (2D box [[x0,y0],[x1,y1]]) from z0 out past the face.
module out_prism(b, z0) translate([b[0][0], b[0][1], z0]) cube([b[1][0] - b[0][0], b[1][1] - b[0][1], 100]);

// Drop-in pocket: pager outline + seat_clear, open to the face, with belt-clip relief.
module seat_pocket() pager_pose() {
    c = seat_clear;
    translate([0, 0, pg_zc - pg_T/2 - c]) linear_extrude(100)
        offset(pg_r + c) square([pg_L - 2*pg_r, pg_W - 2*pg_r], center = true);
    // button reliefs run down to the back face so no button ever bears weight
    for (b = [pg_face_btns, pg_side_btn])
        out_prism([[b[0][0] - c, b[0][1] - c], [b[1][0] + c, b[1][1] + c]], pg_zc - pg_T/2 - c);
    gbox(pg_clip_box, clip_relief);
}

// Both short ends open through the dock's side faces: the port end for plugs,
// the vent end for exhaust; both give a pinch grip on the pager's ends.
module end_windows() pager_pose()
    for (sx = [-1, 1])
        out_prism([[sx > 0 ? pg_L/2 - pg_r : -Wd, -pg_W/2 + win_inset],
                   [sx > 0 ? Wd : -pg_L/2 + pg_r, pg_W/2 - win_inset]], pg_zc - pg_T/2 - seat_clear);

module dock() {
    difference() {
        body_shell();
        fan_slot();
        seat_pocket();
        end_windows();
    }
}
module coupon() {}
module gasket() {}
