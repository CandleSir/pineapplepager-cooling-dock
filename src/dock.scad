// Pineapple Pager cooling dock — entry point.
//   openscad -D fan_size=60 -D fan_t=25 -D 'part="dock"' -o dock-60x25.stl src/dock.scad
// part: "dock" | "coupon" | "gasket" | "gauge" | "fan-gauge" | "filter-grid" | "filter-cap"
include <lib.scad>

part = "dock";

if (part == "dock") dock();
else if (part == "coupon") coupon();
else if (part == "gasket") gasket();
else if (part == "gauge") fit_gauge();
else if (part == "fan-gauge") fan_gauge();
else if (part == "filter-grid") filter_grid();
else if (part == "filter-cap") filter_cap();
