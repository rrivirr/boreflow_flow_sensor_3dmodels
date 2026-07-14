// Round Protractor with pole-mount cylinder
// 2 inches diameter, 2mm thick, 0.25" center hole
// Mounting cylinder on underside: fits 5/16" pole, 3cm tall
// All units in mm (1 inch = 25.4mm)

// ── Parameters ──────────────────────────────────────────────
disk_diameter  = 2 * 25.4;       // 50.8 mm
disk_radius    = disk_diameter / 2;
disk_thickness = 2;              // 2 mm

hole_diameter  = 0.25 * 25.4;   // 6.35 mm
hole_radius    = hole_diameter / 2;

// Mounting cylinder (underside, pole socket)
pole_nominal   = 11.55; // 7.9375 mm — nominal 5/16" pole OD
mount_id       = pole_nominal + 0.4;  // ~8.34 mm — slip fit clearance
mount_wall     = 2.5;                 // wall thickness in mm
mount_od       = mount_id + 2 * mount_wall;
mount_height   = 30;                  // 3 cm

// Tick mark depths (how far inward from the edge)
tick_depth_5deg  = 1.5;   // every 5°
tick_depth_10deg = 3.0;   // every 10°
tick_depth_30deg = 5.0;   // every 30°

tick_width    = 0.4;      // width of each tick line
label_inset   = 7.5;      // how far inward from edge to place text centres
label_size    = 2.2;      // font size in mm
label_depth   = 0.5;      // emboss depth for numbers

$fn = 120;

// ── Helper: one tick mark at a given angle ───────────────────
module tick(angle, depth) {
    r_outer = disk_radius;
    r_inner = disk_radius - depth;
    rotate([0, 0, angle])
        translate([r_inner, -tick_width / 2, 0])
            cube([depth, tick_width, disk_thickness + 0.01]);
}

// ── Helper: one embossed degree label ────────────────────────
module degree_label(angle, label) {
    r_text = disk_radius - label_inset;
    rotate([0, 0, angle])
        translate([r_text, 0, disk_thickness - label_depth])
            rotate([0, 0, -angle + 90])          // keep text upright
                linear_extrude(height = label_depth + 0.01)
                    text(label,
                         size   = label_size,
                         halign = "center",
                         valign = "center",
                         font   = "Liberation Sans:style=Bold");
}

// ── Main body ────────────────────────────────────────────────
difference() {

    // Base disk
    cylinder(h = disk_thickness, d = disk_diameter, center = false);

    // Centre hole — passes all the way through
    translate([0, 0, -0.01])
        cylinder(h = disk_thickness + 0.02, d = hole_diameter, center = false);

    // ── Tick marks (every 5°, 10°, 30°) ──
    for (a = [0 : 5 : 355]) {
        depth =
            (a % 30 == 0) ? tick_depth_30deg :
            (a % 10 == 0) ? tick_depth_10deg :
                             tick_depth_5deg;
        tick(a, depth);
    }

    // ── Degree labels every 10° ──
    for (a = [0 : 10 : 350]) {
        degree_label(a, str(a));
    }
}

// ── Mounting cylinder (underside pole socket) ────────────────
difference() {
    // Outer shell — sits flush against the underside of the disk (z=0 downward)
    translate([0, 0, -mount_height])
        cylinder(h = mount_height, d = mount_od, center = false);

    // Bore — open all the way through (bottom of socket up through disk top)
    translate([0, 0, -(mount_height + 0.01)])
        cylinder(h = mount_height + disk_thickness + 0.02, d = mount_id, center = false);
}


