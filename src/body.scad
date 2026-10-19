// Dock body.

// The seat slab: the 45 deg front face down to a wall behind the pocket, full width.
module seat_block() let(s = sin(seat_angle), c = cos(seat_angle))
    rotate([90, 0, 90]) linear_extrude(Wd, center = true)
        polygon([[0, 0], [slab_d/s, 0], [(slab_d + H*c)/s, H], [H*c/s, H]]);

module fan_housing_local() translate(housing_box[0]) cube(housing_box[1] - housing_box[0]);

// Sides and back sweep from the seat down to the fan housing; the housing's floor
// shadow keeps the base flat under the tilted housing.
module body_shell() hull() {
    seat_block();
    fan_pose() fan_housing_local();
    linear_extrude(0.01) projection() fan_pose() fan_housing_local();
}

// Air hole through the land: a teardrop (prints without supports) cut flat at the
// circle's top, so it stays inside the fan frame.
module hole2d() intersection() {
    hull() {
        circle(hole_r);
        translate([0, hole_r * sqrt(2)]) square(0.01, center = true);
    }
    translate([-hole_r - 1, -hole_r - 1]) square([2*hole_r + 2, 2*hole_r + 1]);
}

// Slot cuts (fan frame): the slot, open at the top; the rear window between the lips;
// cable-bump reliefs at both lower corners, open out the back; the air hole.
// g grows every cut but the hole (tests use it to prove wall thickness).
module slot_local(g = 0, hole = true) {
    a = fan_size/2 + fan_clear + g;
    translate([-a, -a, -g]) cube([2*a, 200, slot_depth + 2*g]);
    w = fan_size/2 - fan_lip + g;
    translate([-w, -w, slot_depth - 0.01]) cube([2*w, 200, 100]);
    r0 = fan_size/2 - 6 - fan_nub[0] - 1;   // inner end of the bump's run along the edge
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([r0 - g, -fan_size/2 - relief - g, -g])
            cube([fan_size/2 + relief - r0 + 2*g, fan_size/2 + relief - r0 + 2*g, 100]);
    if (hole) translate([0, 0, -wall - 1]) linear_extrude(wall + 1.01) hole2d();
}

module fan_slot(g = 0, hole = true) fan_pose() slot_local(g, hole);

// Posts from the chamber floor to the lowest edge of the clip pocket's wall, which
// otherwise hangs in mid-air; ends plus enough between to keep spans <= bridge_max.
module clip_wall_posts() let(g = clip_relief + wall,
                             x0 = pg_clip_box[0][0] - g, x1 = pg_clip_box[1][0] + g,
                             n = ceil((x1 - x0 - rib_w) / bridge_max),
                             r = pose_pt([0, pg_clip_box[0][1] - g, pg_clip_box[0][2] - g]))
    for (i = [0 : n])
        translate([x0 + i*(x1 - x0 - rib_w)/n, r[1] - wall/2, -1]) cube([rib_w, wall, r[2] + 1.5]);

// Pager-frame prism: footprint `b` (2D box [[x0,y0],[x1,y1]]) from z0 out past the face.
module out_prism(b, z0) translate([b[0][0], b[0][1], z0]) cube([b[1][0] - b[0][0], b[1][1] - b[0][1], 100]);

// Pocket plan (pager frame): outline + seat_clear, but seat_clear_top on the +Y wall,
// plus the button reliefs. Shared by the dock and the fit gauge.
module pocket_plan(g = 0) {
    c = seat_clear + g;
    ct = seat_clear_top + g;
    translate([0, (ct - c)/2])
        offset(pg_r + c) square([pg_L - 2*pg_r, pg_W - 2*pg_r - (c - ct)], center = true);
    for (b = [pg_face_btns, pg_side_btn])
        translate([b[0][0] - c, b[0][1] - c]) square([b[1][0] - b[0][0] + 2*c, b[1][1] - b[0][1] + 2*c]);
}

// Drop-in pocket, open to the face, with belt-clip relief. Button reliefs run down to
// the back face so no button ever bears weight.
// g grows every cut (tests use it to prove wall thickness to the chamber).
module seat_pocket(g = 0) pager_pose() {
    translate([0, 0, pg_zc - pg_T/2 - seat_clear - g]) linear_extrude(100) pocket_plan(g);
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

// Chamber -> pager: open channels along the -Y edge in front of both grilles.
module intake_duct() pager_pose()
    for (v = vent_lo) {
        zb = pg_zc - pg_T/2 - seat_clear - wall - duct_dip;
        translate([v[0] - vent_margin, -pg_W/2 - duct_w, zb])
            cube([v[1] - v[0] + 2*vent_margin, duct_w + 1, v[3] + duct_top_margin - zb]);
    }

// Pager -> room: chamber beyond the +Y grille, open to the face under the bar grille.
module exhaust_chamber(g = 0) pager_pose() let(v = vent_hi)
    translate([v[0] - vent_margin - g, pg_W/2 - 1, pg_zc - pg_T/2 - seat_clear - g])
        cube([v[1] - v[0] + 2*(vent_margin + g), 1 + seat_clear + exh_w + g, 100]);

module bar_grille() pager_pose() let(v = vent_hi, x0 = v[0] - vent_margin,
                                      x1 = v[1] + vent_margin, y0 = pg_W/2 + seat_clear_top) {
    translate([x0, y0, face_z - grille_t]) cube([x1 - x0, grille_rim, grille_t]);
    for (x = [x0 + grille_gap : grille_bar + grille_gap : x1 - grille_bar])
        translate([x, y0, face_z - grille_t]) cube([grille_bar, exh_w + 0.01, grille_t]);
}

// Finger notch over the +Y side button.
module button_notch(g = 0) pager_pose() let(cx = (btn_hi[0] + btn_hi[1])/2)
    translate([cx - notch_w/2 - g, pg_W/2 - 1, btn_hi[2] - 3 - g])
        cube([notch_w + 2*g, 1 + seat_clear + notch_len + g, 100]);

// Optional TPU lip seats in this groove in the pocket's -Y wall, above the duct.
module gasket_groove() pager_pose()
    translate([-pg_L/2 + pg_r, -pg_W/2 - seat_clear - groove_d, groove_z])
        cube([pg_L - 2*pg_r, groove_d + 0.01, groove_w]);

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
        intake_duct();
        exhaust_chamber();
        button_notch();
        gasket_groove();
        pager_cable_guide();
    }
    bar_grille();
}
// Seat cradle from the face down to the floor, laid flat (face up) for printing.
cradle_t_lo = seat_u0 - duct_w - wall - 3;
cradle_t_hi = seat_u0 + pg_W + seat_clear + notch_len + wall + 3;
module coupon()
    translate([0, -cradle_t_lo, cradle_t]) rotate([-seat_angle, 0, 0]) intersection() {
        dock();
        rotate([seat_angle, 0, 0]) translate([-(pg_L/2 + 10), cradle_t_lo, -cradle_t])
            cube([pg_L + 20, cradle_t_hi - cradle_t_lo, cradle_t]);
    }

// Fit gauge: a collar with the pocket's walls, printed flat. Slide it onto the pager to
// mid-thickness to feel the seat's fit for a few grams instead of a full coupon.
module fit_gauge() linear_extrude(gauge_h) difference() {
    offset(delta = wall) pocket_plan();
    pocket_plan();
}

// Optional TPU strip for the -Y wall groove; stands seat_clear + 0.3 proud so it
// presses on the pager's -Y edge above the duct. Printed flat.
gasket_len = pg_L - 2*pg_r - 0.4;
gasket_d = groove_d + seat_clear + 0.3;
module gasket() cube([gasket_len, gasket_d, groove_w - 0.1]);
module gasket_seated() pager_pose()
    translate([-pg_L/2 + pg_r + 0.2, -pg_W/2 - seat_clear - groove_d + 0.05, groove_z + 0.05])
        gasket();
