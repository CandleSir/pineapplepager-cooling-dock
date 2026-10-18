// Pineapple Pager cooling dock — entry point.
//   openscad -D fan_size=92 -D 'part="dock"' -o dock-92.stl src/dock.scad
// part: "dock" | "coupon" | "gasket" | "gauge"
include <lib.scad>

part = "dock";

if (part == "dock") dock();
else if (part == "coupon") coupon();
else if (part == "gasket") gasket();
else if (part == "gauge") fit_gauge();
