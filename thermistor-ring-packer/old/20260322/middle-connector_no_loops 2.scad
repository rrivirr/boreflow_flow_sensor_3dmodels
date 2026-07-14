// ===================== PARAMETERS =====================
od           = 3.7 * 25.4;  // outer diameter (3.8 inches)
wall         = 1.5;          // wall thickness
h_body       = 40;

// top ring
top_z       = h_body;
top_h       = 3;
// alignment key
key_w       = 3;     // tangential width
key_h       = 2;     // height (Z)
key_depth   = 1;     // radial depth

// inner ledge (sensor mount disc rests on this)
ledge_w     = 2;     // radial width of ledge (extends inward from inner wall)
ledge_h     = 1.5;   // thickness of ledge in Z

// hole pattern
hole_r = od/2;

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

// -------- Keepout settings --------
keepout_margin = 0.8;
keepout_z0     = pocket_z0;
keepout_h      = pocket_h + 1.0;
// -----------------------------------------------------------

// spacing parameters
z_step    = 3.5;     // vertical spacing
ang_step  = 7;       // angular spacing in degrees
// ======================================================

// ---------- Hole module ----------
module hole_pattern(diam, z_start, z_step, z_end, ang_start) {
  for(z = [z_start:z_step:z_end]) {
    for(angle = [ang_start:ang_step:ang_start+360-ang_step]) {
      rotate([0,0,angle])
        translate([hole_r,0,z])
          rotate([0,90,0])
            cylinder(h=10, d=diam, center=true);
    }
  }
}

// ---------- Keepout volumes ----------
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
      cylinder(h = top_h, d = od);
      cylinder(h = top_h, d = od - 2*wall);
    }
    // alignment key (protrudes inward from inner wall, sits on groove floor)
    translate([(od - 2*wall)/2 - key_depth, -key_w/2, 0])
      cube([key_depth, key_w, key_h]);
  }

  // ===================== INNER LEDGE =====================
  // Sensor mount disc rests on this ledge.
  // Top face is flush with bottom of top ring (z = top_z),
  // so a disc of height = top_h sits flush with the top of the connector.
  translate([0, 0, top_z - ledge_h])
    difference() {
      cylinder(h = ledge_h, d = od - 2*wall);
      cylinder(h = ledge_h, d = od - 2*wall - 2*ledge_w);
    }

  // ===================== BODY =====================
  difference() {

    // main shell
    difference() {
      cylinder(h = h_body, d = od);
      cylinder(h = h_body, d = od - 2*wall);
    }

    // --- subtract HOLES, but NOT inside the keepout zone ---
    difference() {
      union() {
        hole_pattern(1.9,  z_step,   z_step, h_body, 0);
        hole_pattern(1.9,  z_step/2, z_step, h_body, ang_step/2);
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
