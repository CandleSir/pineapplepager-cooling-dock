// Snap-together dust filter for the fan's intake side (push mode): MERV 8 media
// between a grid frame (fan side, keeps the media out of the blades) and a cap.
// Both print flat; the grid frame's corner pegs press through the media's corners
// into the cap's holes.

function peg_at() = let(o = fan_size/2 - filter_border/2) [for (x = [-o, o], y = [-o, o]) [x, y]];

module frame_border() difference() {
    square(fan_size, center = true);
    square(fan_size - 2*filter_border, center = true);
}

module filter_grid() {
    linear_extrude(frame_t) {
        frame_border();
        intersection() {
            square(fan_size - 2*filter_border + 0.02, center = true);
            for (a = [0, 90]) rotate(a)
                for (x = [-fan_size/2 : grid_pitch : fan_size/2])
                    translate([x - grid_bar/2, -fan_size/2]) square([grid_bar, fan_size]);
        }
    }
    for (p = peg_at()) translate([p[0], p[1], frame_t - 0.01])
        cylinder(d = peg_d, h = frame_t + filter_gap - 0.2 + 0.01, $fn = 24);
}

module filter_cap() linear_extrude(frame_t) difference() {
    frame_border();
    for (p = peg_at()) translate(p) circle(d = peg_d + peg_fit, $fn = 24);
}
