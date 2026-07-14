// ===================== PARAMETERS =====================
spoke_len = 17.5;
spoke_w   = 5;
spoke_h   = 5;

spoke_offsetX = 8;
spoke_offsetY = -spoke_w/2;
spoke_z0      = 0;

// keepout prevents hole perforations from breaking the rectangle
keepout_margin = 1.0;           // increase if you still see “half hexagons”
keepout_h      = spoke_h + 1.0; // protect slightly more than spoke height
// ======================================================


// ---------- Hole module ----------
module hole_pattern(diam, z_start, z_step, z_end, ang_start) {
  for(z = [z_start:z_step:z_end]) {
    for(angle = [ang_start:10:ang_start+350]) {
      rotate([0,0,angle])
        translate([24.5,0,z])
          rotate([0,90,0])
            cylinder(h=10, d=diam, center=true);
    }
  }
}


// ---------- Keepout volumes (stop holes near spoke rectangle) ----------
module keepout_volumes() {
  for(i = [0:180:359]) {
    rotate([0,0,i])
      translate([spoke_offsetX - keepout_margin,
                 spoke_offsetY - keepout_margin,
                 spoke_z0])
        cube([spoke_len + 2*keepout_margin,
              spoke_w   + 2*keepout_margin,
              keepout_h]);
  }
}


union() {

  // ===================== TOP FEATURE =====================
  translate([0,0,40]) {
    difference() {
      difference() {
        cylinder(h=5, d=49);
        cylinder(h=5, d=21.1);
      }
      translate([12,-6.5,0]) cube([9,13,5]);
    }
  }


  // ===================== BODY =====================
  difference() {

    // main shell
    difference() {
      cylinder(h=40, d=49);
      cylinder(h=40, d=46);
    }

    // --- holes everywhere EXCEPT the keepout rectangle zone ---
    difference() {
      union() {
        hole_pattern(2.0,  5,   5, 35, 0);
        hole_pattern(2.0,  2.5, 5, 35, 5);
      }
      keepout_volumes();
    }

    // --- rectangular spoke POCKETS (clean rectangle) ---
    for(i = [0:180:359]) {
      rotate([0,0,i])
        translate([spoke_offsetX, spoke_offsetY, spoke_z0])
          cube([spoke_len, spoke_w, spoke_h]);
    }
  }
}
