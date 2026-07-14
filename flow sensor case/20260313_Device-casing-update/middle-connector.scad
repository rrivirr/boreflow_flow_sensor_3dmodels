// ===================== PARAMETERS =====================
h_body       = 40;
d_outer_body = 49;
d_inner_body = 46;

// top ring
top_z       = 40;
top_h       = 3;
top_d_outer = 49;
top_d_inner = 47.5;

// hole pattern
hole_r = 24.5;

// spoke pocket (your separate printed spoke will fit here)
spoke_len = 16.6;
spoke_w   = 5;
spoke_h   = 5;

// pocket clearance (optional)
clr = 0.2;
pocket_len = spoke_len + clr;
pocket_w   = spoke_w   + clr;
pocket_h   = spoke_h   + clr;

// where pocket starts
spoke_offsetX = 8;
spoke_offsetY = -spoke_w/2;
pocket_z0     = 0;      // pocket starts at z=0
// ======================================================


// -------- Keepout settings (THIS controls body look) --------
keepout_margin = 0.8;     // SMALL margin so holes remain like image 2
keepout_z0     = pocket_z0;             // same start as pocket
keepout_h      = pocket_h + 1.0;        // only protect around pocket height
// -----------------------------------------------------------


// ---------- Hole module ----------
module hole_pattern(diam, z_start, z_step, z_end, ang_start) {
  for(z = [z_start:z_step:z_end]) {
    for(angle = [ang_start:10:ang_start+350]) {
      rotate([0,0,angle])
        translate([hole_r,0,z])
          rotate([0,90,0])
            cylinder(h=10, d=diam, center=true);
    }
  }
}


// ---------- Keepout volumes (NO perforations only near the pocket) ----------
module keepout_volumes() {
  for(i = [0:180:359]) {
    rotate([0,0,i])
      translate([spoke_offsetX - keepout_margin,
                 spoke_offsetY - keepout_margin,
                 keepout_z0])
        cube([pocket_len + 2*keepout_margin,
              pocket_w   + 2*keepout_margin,
              keepout_h]);
  }
}


union() {

  // ===================== TOP RING =====================
  translate([0,0,top_z]) {
    difference() {
      cylinder(h = top_h, d = top_d_outer);
      cylinder(h = top_h, d = top_d_inner);
    }
  }

  // ===================== BODY =====================
  difference() {

    // main shell
    difference() {
      cylinder(h = h_body, d = d_outer_body);
      cylinder(h = h_body, d = d_inner_body);
    }

    // --- subtract HOLES, but NOT inside the (small) keepout zone ---
    difference() {
      union() {
        hole_pattern(2.0,  5,   5, 35, 0);
        hole_pattern(2.2,  2.5, 5, 35, 5);
      }
      keepout_volumes();
    }

    // --- subtract RECTANGULAR spoke pockets ---
    for(i = [0:180:359]) {
      rotate([0,0,i])
        translate([spoke_offsetX, spoke_offsetY, pocket_z0])
          cube([pocket_len, pocket_w, pocket_h]);
    }
  }
}
