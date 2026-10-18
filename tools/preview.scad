// Preview renders: dock with ghosted pager and fan, or a side section
// through the right-hand grille (x = 15) showing the air path.
include <../src/lib.scad>

view = "front";
xc = 15;

module cut2d() projection(cut = true) rotate([0, -90, 0]) translate([-xc, 0, 0]) children();

if (view == "section") {
    color("Goldenrod") cut2d() dock();
    color("Crimson") cut2d() pager_pose() pager_envelope(true);
    color("RoyalBlue") cut2d() fan_pose() fan_envelope();
} else {
    color("Goldenrod") dock();
    %pager_pose() pager_envelope(true);
    %fan_pose() fan_envelope();
}
