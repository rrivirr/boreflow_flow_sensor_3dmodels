// Round Protractor with pole-mount cylinder
// 2 inches diameter, 2mm thick, 0.25" center hole
// Mounting cylinder on underside: hollow tube with an internal stop 1 cm from far end
// All units in mm (1 inch = 25.4mm)

// ── Parameters ──────────────────────────────────────────────
disk_diameter  = 2 * 25.4;       // 50.8 mm
disk_radius    = disk_diameter / 2;
disk_thickness = 2;              // 2 mm

hole_diameter  = 0.25 * 25.4;    // 6.35 mm
hole_radius    = hole_diameter / 2;

// Mounting tube (underside)
pole_nominal   = 11.00;
mount_id       = pole_nominal + 0.4;  // 11.40 mm ID
mount_wall     = 2.5;
mount_od       = mount_id + 2 * mount_wall;
mount_height   = 240;                 // 24 cm

// ── Internal stop settings ───────────────────────────────────
// Metal pipe inserts from FAR end (bottom). Limit insertion to 1 cm.
insert_depth   = 10;     // 1 cm

// Thickness of the stop ring along the tube axis
stop_thickness = 3;      // mm (2–5 mm is typical)

// How much smaller the opening becomes at the stop (creates the shoulder).
// Example: if metal pipe OD is 11.12 mm, you might set stop_opening_d = 11.12 or slightly less.
stop_opening_d = 11.12;  // CHANGE if needed

// Tick mark depths
tick_depth_5deg  = 1.5;
tick_depth_10deg = 3.0;
tick_depth_30deg = 5.0;

tick_width    = 0.4;
label_inset   = 7.5;
label_size    = 2.2;
label_depth   = 0.5;

$fn = 120;

// ── Helper: one tick mark at a given angle ───────────────────
module tick(angle, depth) {
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
            rotate([0, 0, -angle + 90])
                linear_extrude(height = label_depth + 0.01)
                    text(label,
                         size   = label_size,
                         halign = "center",
                         valign = "center",
                         font   = "Liberation Sans:style=Bold");
}

// ── Main disk ────────────────────────────────────────────────
difference() {
    cylinder(h = disk_thickness, d = disk_diameter, center = false);

    translate([0, 0, -0.01])
        cylinder(h = disk_thickness + 0.02, d = hole_diameter, center = false);

    for (a = [0 : 5 : 355]) {
        depth =
            (a % 30 == 0) ? tick_depth_30deg :
            (a % 10 == 0) ? tick_depth_10deg :
                             tick_depth_5deg;
        tick(a, depth);
    }

    for (a = [0 : 10 : 350]) {
        degree_label(a, str(a));
    }
}

// ── Hollow tube + internal stop ──────────────────────────────
union() {

    // 1) The hollow tube (open all the way through)
    difference() {
        translate([0, 0, -mount_height])
            cylinder(h = mount_height, d = mount_od, center = false);

        // Hollow bore through full tube length
        translate([0, 0, -(mount_height + 0.01)])
            cylinder(h = mount_height + 0.02, d = mount_id, center = false);
    }

    // 2) Internal stop ring located 1 cm from the FAR end (bottom)
    // Bottom end is at z = -mount_height
    // Stop starts at z = -mount_height + insert_depth
    translate([0, 0, -mount_height + insert_depth])
        difference() {
            // This ring fills the inside up to mount_id
            cylinder(h = stop_thickness, d = mount_id, center = false);

            // But we re-open a smaller hole so the tube remains "hollow"
            // This creates a shoulder that blocks a larger metal pipe from going deeper.
            translate([0, 0, -0.01])
                cylinder(h = stop_thickness + 0.02, d = stop_opening_d, center = false);
        }
}