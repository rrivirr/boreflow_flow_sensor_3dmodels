// ===================== PARAMETERS =====================
od        = 3.7 * 25.4;  // outer diameter (3.8 inches)
wall      = 1.5;          // wall thickness
body_h    = 40;
spoke_len = 25;
spoke_w   = 4;
spoke_h   = 4;
spoke_offsetX = 8;
spoke_offsetY = -spoke_w/2;
spoke_z0      = 0;
// keepout prevents hole perforations from breaking the rectangle
keepout_margin = 1.0;
keepout_h      = spoke_h + 1.0;
// spacing parameters
z_step    = 3.5;     // vertical spacing
ang_step  = 7;       // angular spacing in degrees
top_h     = 2.5;     // top cap thickness
top_r_margin = 2;    // margin from outer edge for top holes
// ======================================================

// ---------- Hole module ----------
module hole_pattern(diam, z_start, z_step, z_end, ang_start) {
  for(z = [z_start:z_step:z_end]) {
    for(angle = [ang_start:ang_step:ang_start+360-ang_step]) {
      rotate([0,0,angle])
        translate([od/2,0,z])
          rotate([0,90,0])
            cylinder(h=10, d=diam, center=true);
    }
  }
}

// ---------- Top hole module (Cartesian grid) ----------
module top_hole_pattern_grid(diam, spacing) {
  top_r = od/2 - top_r_margin;
  for(x = [-top_r : spacing : top_r]) {
    for(y = [-top_r : spacing : top_r]) {
      if(x*x + y*y <= top_r*top_r)
        translate([x, y, -1])
          cylinder(h=top_h+2, d=diam);
    }
  }
}

// ---------- Keepout volumes ----------
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
  translate([0,0,body_h]) {
    difference() {
      difference() {
        cylinder(h=top_h, d=od);
        cylinder(h=top_h+2, d=0.81*25.4);
      }
      // --- three access holes (0.65" dia, 1/2" from edge, 45° apart) ---
      for(a = [-45, 0, 45]) {
        rotate([0,0,a])
          translate([od/2 - 0.5*25.4, 0, -1])
            cylinder(h=top_h+2, d=0.65*25.4);
      }
      // --- evenly spaced top holes ---
      top_hole_pattern_grid(1.9, z_step);
    }
  }
  // ===================== BODY =====================
  difference() {
    // main shell
    difference() {
      cylinder(h=body_h, d=od);
      cylinder(h=body_h, d=od - 2*wall);
    }
    // --- holes minus keepout ---
    difference() {
      union() {
        hole_pattern(1.9,  z_step,   z_step, body_h, 0);
        hole_pattern(1.9,  z_step/2, z_step, body_h, ang_step/2);
      }
      keepout_volumes();
    }
    // --- spoke pockets ---
    for(i = [0:180:359]) {
      rotate([0,0,i])
        translate([spoke_offsetX, spoke_offsetY, spoke_z0])
          cube([spoke_len, spoke_w, spoke_h]);
    }
  }
}
