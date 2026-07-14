// ===================== PARAMETERS =====================
od        = 3.7 * 25.4;  // outer diameter of mating shell (must match middle connector)
wall      = 1.5;          // shell wall thickness (must match middle connector)
fit_clr   = 0.4;          // diametral clearance for disc inside top ring
disc_d    = od - 2*wall - fit_clr;  // disc OD ~90.58 mm (fits inside top ring)
disc_h    = 3;            // matches top_h of middle connector for flush fit
center_d  = 20;            // center bore diameter
post_d    = 28;            // upper post outer diameter
post_h    = 6;
ring_w    = 10;            // outer ring width
n_spokes  = 3;             // number of spokes
spoke_w   = 6;             // spoke width (tangential)
// alignment key notch (matches middle connector key)
key_w       = 3;     // tangential width
key_h       = 2;     // height (Z)
key_depth   = 1;     // radial depth
key_clr     = 0.2;   // clearance around key
// ======================================================

// upper post
translate([0,0,disc_h]) {
    difference() {
        cylinder(h=post_h, d=post_d);
        cylinder(h=post_h, d=center_d);
    }
}

// lower platform: outer ring + inner hub + spokes
translate([0,0,0]) {
    // outer ring with key notch
    difference() {
        cylinder(h=disc_h, d=disc_d);
        cylinder(h=disc_h, d=disc_d - 2*ring_w);
        // key notch (cut from bottom so mount rests on key)
        translate([disc_d/2 - key_depth - key_clr,
                   -(key_w + 2*key_clr)/2,
                   -1])
            cube([key_depth + key_clr + 1,
                  key_w + 2*key_clr,
                  key_h + key_clr + 1]);
    }

    // inner hub (solid to 20mm radius)
    difference() {
        cylinder(h=disc_h, d=40);
        cylinder(h=disc_h, d=center_d);
    }

    // spokes (start inward to fully connect to curved hub)
    spoke_r_start = sqrt(20*20 - (spoke_w/2)*(spoke_w/2));
    for(i = [0 : n_spokes-1]) {
        rotate([0, 0, i * 360/n_spokes])
            translate([spoke_r_start, -spoke_w/2, 0])
                cube([disc_d/2 - ring_w - spoke_r_start, spoke_w, disc_h]);
    }
}
