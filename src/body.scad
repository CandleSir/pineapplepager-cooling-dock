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

module dock() {
    difference() {
        body_shell();
        fan_slot();
    }
}
module coupon() {}
module gasket() {}
