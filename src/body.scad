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
// g grows every cut (tests use it to prove wall thickness to the plenum).
module seat_pocket(g = 0) pager_pose() {
    c = seat_clear + g;
    zb = pg_zc - pg_T/2 - c;
    translate([0, 0, zb]) linear_extrude(100)
        offset(pg_r + c) square([pg_L - 2*pg_r, pg_W - 2*pg_r], center = true);
    // button reliefs run down to the back face so no button ever bears weight
    for (b = [pg_face_btns, pg_side_btn])
        out_prism([[b[0][0] - c, b[0][1] - c], [b[1][0] + c, b[1][1] + c]], zb);
    gbox(pg_clip_box, clip_relief + g);
}

// Both short ends open through the dock's side faces: the port end for plugs,
// the vent end for exhaust; both give a pinch grip on the pager's ends.
module end_windows(g = 0) pager_pose()
    for (sx = [-1, 1])
        out_prism([[sx > 0 ? pg_L/2 - pg_r : -Wd, -pg_W/2 + win_inset - g],
                   [sx > 0 ? Wd : -pg_L/2 + pg_r, pg_W/2 - win_inset + g]],
                  pg_zc - pg_T/2 - seat_clear - g);

// Half-space behind the seat floor slab (everything deeper than the pocket + a wall).
module behind_slab()
    translate(-(seat_depth + seat_clear + wall) * slope_n()) rotate([seat_angle, 0, 0])
        translate([-500, -500, -1000]) cube(1000);

// Sealed air volume between the fan tray and the seat.
module plenum() difference() {
    intersection() {
        rotate([90, 0, 90]) linear_extrude(Wd - 2*wall, center = true)
            offset(delta = -wall) polygon([[0, 0], [D, 0], [D - run, H], [run, H]]);
        behind_slab();
    }
    pager_pose() gbox(pg_clip_box, clip_relief + wall);
    fan_pose() translate([-fan_tray/2 - wall, -fan_tray/2 - wall, -fan_clear - wall])
        cube([fan_tray + 2*wall, fan_tray + 2*wall, 200]);
}

// Plenum -> pager: open channels along the -Y edge in front of both grilles.
module intake_duct() pager_pose()
    for (v = vent_lo) {
        zb = pg_zc - pg_T/2 - seat_clear - wall - duct_dip;
        translate([v[0] - vent_margin, -pg_W/2 - duct_w, zb])
            cube([v[1] - v[0] + 2*vent_margin, duct_w + 1, v[3] + vent_margin - zb]);
    }

// Pager -> room: chamber beyond the +Y grille, open to the face under the bar grille.
module exhaust_chamber(g = 0) pager_pose() let(v = vent_hi)
    translate([v[0] - vent_margin - g, pg_W/2 - 1, pg_zc - pg_T/2 - seat_clear - g])
        cube([v[1] - v[0] + 2*(vent_margin + g), 1 + seat_clear + exh_w + g, 100]);

module bar_grille() pager_pose() let(v = vent_hi, x0 = v[0] - vent_margin,
                                      x1 = v[1] + vent_margin, y0 = pg_W/2 + seat_clear) {
    translate([x0, y0, face_z - grille_t]) cube([x1 - x0, grille_rim, grille_t]);
    for (x = [x0 + grille_gap : grille_bar + grille_gap : x1 - grille_bar])
        translate([x, y0, face_z - grille_t]) cube([grille_bar, exh_w + 0.01, grille_t]);
}

// Finger notch over the +Y side button.
module button_notch(g = 0) pager_pose() let(cx = (btn_hi[0] + btn_hi[1])/2)
    translate([cx - 7 - g, pg_W/2 - 1, btn_hi[2] - 3 - g])
        cube([14 + 2*g, 1 + seat_clear + 11 + g, 100]);

// Optional TPU lip seats in this groove in the pocket's -Y wall, above the duct.
module gasket_groove() pager_pose()
    translate([-pg_L/2 + pg_r, -pg_W/2 - seat_clear - groove_d, vent_lo[0][3] + vent_margin + 0.3])
        cube([pg_L - 2*pg_r, groove_d + 0.01, groove_w]);

module dock() {
    difference() {
        body_shell();
        fan_slot();
        seat_pocket();
        end_windows();
        plenum();
        intake_duct();
        exhaust_chamber();
        button_notch();
        gasket_groove();
    }
    bar_grille();
}
module coupon() {}
module gasket() {}
