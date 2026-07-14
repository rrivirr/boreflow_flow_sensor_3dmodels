// ============================================================
// Threaded Tube with Domed Caps — Flush 3.3" OD Assembly
// Threading via screw_extrude (Philipp Klostermann method)
// User parameters in inches — converted to mm for OpenSCAD
// ============================================================
//
// Design overview:
//   - Tube: 3.3" OD constant, 3.0" ID, with INTERNAL threads
//     at each end (thread ridges project inward from bore wall).
//   - Cap: skirt with EXTERNAL threads screws INSIDE the tube.
//     A shoulder ring at 3.3" OD butts against the tube end,
//     and a spherical dome sits on top — all flush at 3.3" OD.
//
// No external dependencies.
// ============================================================

/* [Unit Conversion] */
inch = 25.4;  // OpenSCAD works in mm; all parameters below are inches

/* [Tube Dimensions] */
tube_length      = 4.0  * inch;
tube_id          = 2.95  * inch;
tube_od          = 3.15  * inch;

/* [Cap Dimensions] */
cap_total_height = 1.5  * inch;
cap_bottom_hole  = 0.65 * inch;   // center hole in bottom cap
cap_top_hole     = 0.65 * inch;   // center hole in top cap
dome_flat        = 0.15 * inch;   // amount to truncate off dome tip (flat spot for printing)

/* [Thread Parameters] */
thread_height    = 0.6  * inch;
thread_turns     = 4;
cut_thread_percent = 10;

/* [Tolerances & Fit] */
partsgap         = 0.015 * inch;

/* [Cap Skirt] */
skirt_wall       = 0.1  * inch;

/* [Printing & Display] */
layout_to_print  = 1;      // [0:assembled/exploded, 1:print layout]
part_to_print    = 0;      // [0:all, 1:tube, 2:cap]
explode          = 0.75 * inch;
print_distance   = 0.5  * inch;

/* [Resolution] */
fn = 128;                   // [32,64,128,256]

/* [Hidden] */
tol = 0.05 * inch;
wall = (tube_od - tube_id) / 2;

// Thread derived
ThreadSize      = thread_height / thread_turns;
thread_thicknes = ThreadSize / 2;
cut_height      = thread_thicknes * cut_thread_percent / 100;
cut_width       = thread_thicknes * (100 - cut_thread_percent) / 100;

// Geometry derived
bore_r          = tube_id / 2;
skirt_r         = bore_r - thread_thicknes - partsgap;
skirt_inner_r   = skirt_r - skirt_wall;
shoulder_thick  = wall;
cap_skirt_h     = thread_height + ThreadSize;
cap_dome_h      = cap_total_height - cap_skirt_h - shoulder_thick;

// ============================================================
// screw_extrude by Philipp Klostermann
// ============================================================
module screw_extrude(P, r, p, d, sr, er, fn)
{
    anz_pt = len(P);
    steps = round(d * fn / 360);
    mm_per_deg = p / 360;

    VL = [ [r, 0, 0] ];
    PL = [ for (i=[0:1:anz_pt-1]) [0, 1+i, 1+((i+1)%anz_pt)] ];
    V = [
        for (n=[1:1:steps-1])
            let (
                w1 = n * d / steps,
                h1 = mm_per_deg * w1,
                s1 = sin(w1),
                c1 = cos(w1),
                faktor = (w1 < sr)
                    ? (w1 / sr)
                    : ((w1 > (d - er))
                        ? 1 - ((w1 - (d - er)) / er)
                        : 1)
            )
            for (pt = P)
                [r*c1 + pt[0]*c1*faktor,
                 r*s1 + pt[0]*s1*faktor,
                 h1   + pt[1]*faktor]
    ];
    P1 = [
        for (n=[0:1:steps-3])
            for (i=[0:1:anz_pt-1])
                [1+(n*anz_pt)+i,
                 1+(n*anz_pt)+anz_pt+i,
                 1+(n*anz_pt)+anz_pt+(i+1)%anz_pt]
    ];
    P2 = [
        for (n=[0:1:steps-3])
            for (i=[0:1:anz_pt-1])
                [1+(n*anz_pt)+i,
                 1+(n*anz_pt)+anz_pt+(i+1)%anz_pt,
                 1+(n*anz_pt)+(i+1)%anz_pt]
    ];
    VR = [ [r*cos(d), r*sin(d), mm_per_deg*d] ];
    PR = [
        for (i=[0:1:anz_pt-1])
            [1+(steps-1)*anz_pt,
             1+(steps-2)*anz_pt+((i+1)%anz_pt),
             1+(steps-2)*anz_pt+i]
    ];

    VG = concat(VL, V, VR);
    PG = concat(PL, P1, P2, PR);
    convex = round(d/45) + 4;
    polyhedron(VG, PG, convexity=convex);
}

// ============================================================
// Dome shell: hollow spherical cap
// ============================================================
module dome_shell(outer_r, thickness, height, flat=0) {
    R_out = (outer_r*outer_r + height*height) / (2*height);
    R_in  = R_out - thickness;
    cz    = height - R_out;
    trim_h = height - flat;  // truncated height
    difference() {
        intersection() {
            translate([0,0,cz]) sphere(r=R_out, $fn=fn);
            cylinder(r=outer_r+1, h=trim_h, $fn=fn);
        }
        intersection() {
            translate([0,0,cz]) sphere(r=R_in, $fn=fn);
            translate([0,0,-0.001])
                cylinder(r=outer_r+1, h=trim_h+0.001, $fn=fn);
        }
    }
}

// ============================================================
// Tube Body
// Constant OD, internal threads at each end
// ============================================================
module TubeBody() {
    int_P = (cut_thread_percent > 0)
        ? [ [tol*2, -(thread_thicknes-tol)],
            [-cut_width, -cut_height],
            [-cut_width,  cut_height],
            [tol*2,  (thread_thicknes-tol)] ]
        : [ [tol, -(thread_thicknes-tol)],
            [-thread_thicknes, 0],
            [tol,  (thread_thicknes-tol)] ];

    difference() {
        cylinder(r=tube_od/2, h=tube_length, $fn=fn);
        translate([0, 0, -tol])
            cylinder(r=bore_r, h=tube_length + tol*2, $fn=fn);
    }

    // --- Bottom internal threads ---
    difference() {
        translate([0, 0, ThreadSize/2])
            screw_extrude(
                P=int_P, r=bore_r, p=ThreadSize,
                d=360*thread_turns, sr=0, er=45, fn=fn);
        rotate([180,0,0])
            translate([0, 0, -tol])
                cylinder(r=bore_r + thread_thicknes + tol,
                         h=ThreadSize + tol, $fn=fn);
        translate([0, 0, thread_height + ThreadSize])
            cylinder(r=bore_r + thread_thicknes + tol,
                     h=ThreadSize + tol, $fn=fn);
    }

    // --- Top internal threads ---
    difference() {
        translate([0, 0, tube_length - thread_height - ThreadSize/2])
            screw_extrude(
                P=int_P, r=bore_r, p=ThreadSize,
                d=360*thread_turns, sr=0, er=45, fn=fn);
        translate([0, 0, tube_length + tol])
            cylinder(r=bore_r + thread_thicknes + tol,
                     h=ThreadSize + tol, $fn=fn);
        translate([0, 0, tube_length - thread_height - ThreadSize*1.5 - tol])
            cylinder(r=bore_r + thread_thicknes + tol,
                     h=ThreadSize + tol, $fn=fn);
    }
}

// ============================================================
// Domed Cap
// z=0 is the open skirt end, dome is at the top.
// ============================================================
module DomedCap(hole_dia=0) {
    ext_P = (cut_thread_percent > 0)
        ? [ [-tol, thread_thicknes-tol],
            [cut_width, cut_height],
            [cut_width, -cut_height],
            [-tol, -(thread_thicknes-tol)] ]
        : [ [-tol, thread_thicknes-tol],
            [thread_thicknes, 0],
            [-tol, -(thread_thicknes-tol)] ];

    difference() {
        union() {
            // --- Skirt: open cylindrical shell ---
            difference() {
                cylinder(r=skirt_r, h=cap_skirt_h, $fn=fn);
                translate([0, 0, -tol])
                    cylinder(r=skirt_inner_r, h=cap_skirt_h + tol*2, $fn=fn);
            }

            // --- External threads on skirt ---
            difference() {
                translate([0, 0, ThreadSize/2])
                    screw_extrude(
                        P=ext_P, r=skirt_r, p=ThreadSize,
                        d=360*thread_turns, sr=0, er=45, fn=fn);
                translate([0, 0, cap_skirt_h])
                    cylinder(r=bore_r + thread_thicknes + tol,
                             h=ThreadSize + tol, $fn=fn);
                rotate([180, 0, 0])
                    translate([0, 0, -tol])
                        cylinder(r=bore_r + thread_thicknes + tol,
                                 h=ThreadSize + tol, $fn=fn);
            }

            // --- Shoulder ring: flush with tube OD ---
            translate([0, 0, cap_skirt_h])
                difference() {
                    cylinder(r=tube_od/2, h=shoulder_thick, $fn=fn);
                    translate([0, 0, -tol])
                        cylinder(r=skirt_inner_r, h=shoulder_thick + tol*2, $fn=fn);
                }

            // --- Dome shell ---
            if (cap_dome_h > 0) {
                translate([0, 0, cap_skirt_h + shoulder_thick])
                    dome_shell(tube_od/2, wall, cap_dome_h, flat=dome_flat);
            }
        }

        // --- Center hole through dome and shoulder ---
        if (hole_dia > 0) {
            translate([0, 0, -tol])
                cylinder(r=hole_dia/2, h=cap_total_height + tol*2, $fn=fn);
        }
    }
}

// ============================================================
// Layout
// ============================================================
module Assembled() {
    if (part_to_print == 0 || part_to_print == 1) {
        color("SteelBlue", 0.9)
            translate([0, 0, cap_total_height + explode])
                TubeBody();
    }
    if (part_to_print == 0 || part_to_print == 2) {
        // Bottom cap: 1.05" hole, flipped dome-down
        color("Coral", 0.9)
            translate([0, 0, cap_total_height])
                rotate([180, 0, 0])
                    DomedCap(hole_dia=cap_bottom_hole);
        // Top cap: 0.65" hole, dome-up
        color("Coral", 0.9)
            translate([0, 0, cap_total_height + tube_length + explode*2])
                DomedCap(hole_dia=cap_top_hole);
    }
}

module PrintLayout() {
    if (part_to_print == 0 || part_to_print == 1) {
        color("SteelBlue", 0.9)
            TubeBody();
    }
    if (part_to_print == 0 || part_to_print == 2) {
        x_off = tube_od/2 + tube_od/2 + print_distance;
        // Bottom cap (1.05" hole): dome on build plate, open skirt up
        color("Coral", 0.9)
            translate([x_off, 0, cap_total_height - dome_flat])
                rotate([180, 0, 0])
                    DomedCap(hole_dia=cap_bottom_hole);
        // Top cap (0.65" hole): dome on build plate, open skirt up
        color("Coral", 0.9)
            translate([-x_off, 0, cap_total_height - dome_flat])
                rotate([180, 0, 0])
                    DomedCap(hole_dia=cap_top_hole);
    }
}

if (layout_to_print == 1) PrintLayout();
else Assembled();

// ============================================================
// Info
// ============================================================
echo(str("--- Flush Threaded Tube with Domed Caps ---"));
echo(str("Tube: ", tube_length/inch, "\" L, ID=", tube_id/inch, "\", OD=", tube_od/inch, "\""));
echo(str("Wall: ", wall/inch, "\""));
echo(str("Thread: ", thread_turns, " turns, pitch=", ThreadSize/inch, "\", depth=", thread_thicknes/inch, "\""));
echo(str("Cap total height: ", cap_total_height/inch, "\""));
echo(str("  Skirt height: ", cap_skirt_h/inch, "\"  Shoulder: ", shoulder_thick/inch, "\"  Dome: ", cap_dome_h/inch, "\""));
echo(str("Cap skirt OD (at thread root): ", skirt_r*2/inch, "\""));
echo(str("Cap skirt OD (at thread peak): ", (skirt_r + thread_thicknes)*2/inch, "\""));
echo(str("Cap/dome OD (flush): ", tube_od/inch, "\""));
echo(str("Parts gap: ", partsgap/inch, "\" radial"));
echo(str("Wall behind tube threads: ", (tube_od/2 - bore_r)/inch, "\""));
echo(str("Bottom cap hole: ", cap_bottom_hole/inch, "\" dia"));
echo(str("Top cap hole: ", cap_top_hole/inch, "\" dia"));
echo(str("Dome truncation: ", dome_flat/inch, "\" (flat spot for printing)"));
