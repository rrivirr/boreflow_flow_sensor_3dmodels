// ===================== PARAMETERS =====================
od        = 3.6 * 25.4;  // outer diameter (3.8 inches)
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

// hole/loop reference radius
hole_r    = od/2;

// ===================== BOTTOM LIP (matches middle connector) =====================
// Mirror of the middle connector's top lip, on the open end (opposite the closed cap).
bottom_ring_h  = 3;     // matches middle connector top_h
// alignment key (matches middle connector)
key_w       = 3;     // tangential width
key_h       = 2;     // height (Z)
key_depth   = 1;     // radial depth
// inner ledge (mounting ring disc rests against this)
ledge_w     = 2;     // radial width of ledge
ledge_h     = 1.5;   // thickness of ledge in Z

// -------- Loop pattern parameters --------
prot_vgap = 0.9;     // vertical gap between anchor pairs in an X-crossing
loop_peak = 1.2;     // radial peak (mm outward from shell)
loop_diam = 0.7;     // wire diameter
loop_segs = 12;      // curve segments per wire
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

// ---------- Loop modules ----------
function lerp(a, b, t) = a + (b - a) * t;

// Parametric point on a curved wire that bows radially outward by `peak`
// at the midpoint. Endpoints sit on the shell outer surface (r = base_r).
function loop_point(t, ang1, z1, ang2, z2, peak, base_r) =
  let(
    ang = lerp(ang1, ang2, t),
    z   = lerp(z1, z2, t),
    r   = base_r + peak * sin(t * 180)
  )
  [r * cos(ang), r * sin(ang), z];

// Single curved wire as a chain of hulled spheres
module loop_wire(ang1, z1, ang2, z2, peak, diam, base_r, n=12) {
  for(i = [0:n-1]) {
    t1 = i / n;
    t2 = (i + 1) / n;
    hull() {
      translate(loop_point(t1, ang1, z1, ang2, z2, peak, base_r))
        sphere(d=diam, $fn=8);
      translate(loop_point(t2, ang1, z1, ang2, z2, peak, base_r))
        sphere(d=diam, $fn=8);
    }
  }
}

// One X-crossing between anchors at angle `ang` and angle `ang + ang_step`,
// vertically offset by ±prot_vgap/2 around z.
module x_cross(ang, z, peak=loop_peak) {
  v_off    = prot_vgap/2;
  next_ang = ang + ang_step;
  // bottom-left -> top-right
  loop_wire(ang, z - v_off, next_ang, z + v_off, peak, loop_diam, hole_r, loop_segs);
  // top-left -> bottom-right
  loop_wire(ang, z + v_off, next_ang, z - v_off, peak, loop_diam, hole_r, loop_segs);
}

// Two interleaved grids of X-crossings around the cylinder body.
module loop_pattern(z_start, dz, z_end, ang_start) {
  for(z = [z_start : dz : z_end]) {
    for(ang = [ang_start : ang_step : ang_start + 360 - ang_step]) {
      x_cross(ang, z);
    }
  }
}

union() {
  // ===================== TOP FEATURE (closed end) =====================
  translate([0,0,body_h]) {
    difference() {
      difference() {
        cylinder(h=top_h, d=od);
        cylinder(h=top_h+2, d=0.81*25.4);
      }
      // --- three access holes (0.65" dia, 1/2" from edge, 45° apart) ---
/*      for(a = [-45, 0, 45]) {
        rotate([0,0,a])
          translate([od/2 - 0.5*25.4, 0, -1])
            cylinder(h=top_h+2, d=0.65*25.4);
      }
*/      // --- evenly spaced top holes ---
      top_hole_pattern_grid(1.9, z_step);
    }
  }

  // ===================== BOTTOM RING (lip for mounting ring) =====================
  // Mirrors the middle connector's top ring, placed below the body on the open end.
  translate([0, 0, -bottom_ring_h]) {
    difference() {
      cylinder(h = bottom_ring_h, d = od);
      cylinder(h = bottom_ring_h, d = od - 2*wall);
    }
    // alignment key (protrudes inward; sits against underside of ledge)
    translate([(od - 2*wall)/2 - key_depth,
               -key_w/2,
               bottom_ring_h - key_h])
      cube([key_depth, key_w, key_h]);
  }

  // ===================== INNER LEDGE =====================
  // Mounting ring disc rests against this ledge. With bottom_ring_h = 3 and a
  // 3 mm-tall disc, the disc's free face is flush with the bottom of the ring (z = -3).
  translate([0, 0, 0])
    difference() {
      cylinder(h = ledge_h, d = od - 2*wall);
      cylinder(h = ledge_h, d = od - 2*wall - 2*ledge_w);
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

  // ===================== LOOPS =====================
  // Brick-offset relative to the hole pattern: loop anchors sit between holes.
  loop_pattern(z_step/2, z_step, body_h, 0);
  loop_pattern(z_step,   z_step, body_h, ang_step/2);
}
