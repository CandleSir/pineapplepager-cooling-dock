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
    fan_cable_channel(g = wall);
    pager_cable_guide(g = wall);
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

// Rear-face frame: x across, y up the rear slope from the rear-bottom edge, z out of the face.
module rear_frame() multmatrix([[1, 0, 0, 0],
                                [0, rear_t()[1], rear_n()[1], D],
                                [0, rear_t()[2], rear_n()[2], 0],
                                [0, 0, 0, 1]]) children();

// Fan cable: from both lower corners of the tray down the rear face to the
// rear-bottom edge, with two bends for strain relief and a pocket for an
// inline adapter. Open to the outside along its whole length, so no plug
// ever has to pass through a hole.
function cable_path(sx) = let(x0 = sx * (fan_size/2 - 10))
    [[x0, fan_v0 + 6], [x0, 0.65 * fan_v0], [x0 - sx * 9, 0.45 * fan_v0], [x0 - sx * 9, -ch_w]];
adapter_at = [fan_size/2 - 19, 10];   // [x, v] centre, on the +x channel

module fan_cable_channel(g = 0, probe = false) rear_frame() {
    w = probe ? ch_w - 1 : ch_w + 2*g;
    z0 = probe ? -ch_d + 0.5 : -ch_d - g;
    for (sx = [-1, 1]) let(pts = cable_path(sx))
        for (i = [0 : len(pts) - 2])
            hull() for (q = [pts[i], pts[i + 1]])
                translate([q[0], q[1], z0]) cylinder(d = w, h = 100, $fn = 24);
    if (!probe)
        translate([adapter_at[0] - adapter[0]/2 - g, adapter_at[1] - adapter[1]/2 - g, -adapter[2] - g])
            cube([adapter[0] + 2*g, adapter[1] + 2*g, 100]);
}

module adapter_probe() rear_frame()
    translate([adapter_at[0] - adapter[0]/2 + 0.2, adapter_at[1] - adapter[1]/2 + 0.2, -adapter[2] + 0.2])
        cube([adapter[0] - 0.4, adapter[1] - 0.4, adapter[2] + 40]);

// Pager USB cables: a groove down the port-end side face under each port.
module pager_cable_guide(g = 0, probe = false)
    for (pc = port_centres) let(p = pose_pt([port_end_sign * pg_L/2, pc[0], pc[1]]),
                                side = port_end_sign * Wd/2,
                                w = probe ? guide_w - 1 : guide_w + 2*g,
                                d = probe ? guide_d - 0.5 : guide_d + g)
        translate([side - port_end_sign * d + (port_end_sign > 0 ? 0 : -40), p[1] - w/2, probe ? 0.5 : -1 - g])
            cube([d + 40, w, p[2] + 1 + g - (probe ? 1.5 : 0)]);

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
        fan_cable_channel();
        pager_cable_guide();
    }
    bar_grille();
}
// Seat cradle from the face down to the floor, laid flat (face up) for printing.
cradle_t_lo = seat_u0 - duct_w - wall - 3;
cradle_t_hi = seat_u0 + pg_W + seat_clear + 11 + wall + 3;
module coupon()
    translate([0, -cradle_t_lo, cradle_t]) rotate([-seat_angle, 0, 0]) intersection() {
        dock();
        rotate([seat_angle, 0, 0]) translate([-(pg_L/2 + 10), cradle_t_lo, -cradle_t])
            cube([pg_L + 20, cradle_t_hi - cradle_t_lo, cradle_t]);
    }

// Optional TPU strip for the -Y wall groove; stands seat_clear + 0.3 proud so it
// presses on the pager's -Y edge above the duct. Printed flat.
gasket_len = pg_L - 2*pg_r - 0.4;
gasket_d = groove_d + seat_clear + 0.3;
module gasket() cube([gasket_len, gasket_d, groove_w - 0.1]);
module gasket_seated() pager_pose()
    translate([-pg_L/2 + pg_r + 0.2, -pg_W/2 - seat_clear - groove_d, vent_lo[0][3] + vent_margin + 0.3 + 0.05])
        gasket();
