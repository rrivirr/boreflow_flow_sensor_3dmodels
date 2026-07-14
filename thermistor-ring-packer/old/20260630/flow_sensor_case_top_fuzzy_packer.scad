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
// loop parameters (replace protrusions)
prot_vgap = 0.9;     // vertical gap between anchor pairs in an X-crossing
loop_peak = 1.2;     // radial peak (mm outward from shell)
loop_diam = 0.7;     // wire diameter
loop_segs = 12;      // curve segments per wire
prot_l      = 0.4;   // used for anchor vertical offset
loop_floor  = 0.0;       // loops clipped flat at this z (open-end base)
loop_top_clearance = 1;          // gap between top of loops and cap underside
loop_ceiling = body_h - loop_top_clearance;  // loops stop here; keeps the cap/bed edge clean
// spacing parameters
z_step    = 3.5;     // vertical spacing (was 5, reduced 30%)
ang_step  = 7;       // angular spacing in degrees (was 10, reduced 30%)
top_h     = 2.5;       // top cap thickness
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
// ---------- Loop helper functions ----------
function lerp(a, b, t) = a + (b - a) * t;
function loop_point(t, ang1, z1, ang2, z2, r_base, peak) =
  let(
    a = lerp(ang1, ang2, t),
    z = lerp(z1, z2, t),
    r = r_base + peak * sin(t * 180)
  )
  [r * cos(a), r * sin(a), z];

// ---------- Single loop wire ----------
module loop_wire(ang1, z1, ang2, z2, r_base, peak, diam, n=12) {
  for(i = [0:n-1]) {
    t1 = i / n;
    t2 = (i + 1) / n;
    hull() {
      translate(loop_point(t1, ang1, z1, ang2, z2, r_base, peak))
        sphere(d=diam, $fn=8);
      translate(loop_point(t2, ang1, z1, ang2, z2, r_base, peak))
        sphere(d=diam, $fn=8);
    }
  }
}

// ---------- Loop pattern ----------
module loop_pattern(z_start, z_stp, z_end, ang_start) {
  v_off = prot_vgap/2 + prot_l/2;
  for(z = [z_start:z_stp:z_end]) {
    for(angle = [ang_start:ang_step:ang_start+360-ang_step]) {
      next_ang = angle + ang_step;
      // X-crossing: bottom->top-right, top->bottom-right
      loop_wire(angle, z - v_off, next_ang, z + v_off,
                od/2 - loop_diam/2, loop_peak, loop_diam, loop_segs);
      loop_wire(angle, z + v_off, next_ang, z - v_off,
                od/2 - loop_diam/2, loop_peak, loop_diam, loop_segs);
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
      // --- three access holes (0.65" dia, 1/2" from edge, 45 deg apart) ---
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
  // ===================== LOOPS =====================
  // X-crossing wire loops between anchor points, trimmed by keepout.
  // Clipped flat between loop_floor and loop_ceiling. The ceiling stops the
  // loops short of the top cap so the cap-edge (print bed contact) stays clean.
  intersection() {
    translate([0, 0, loop_floor])
      linear_extrude(height = loop_ceiling - loop_floor)
        circle(d = od + 2*loop_peak + 10);
    difference() {
      union() {
        loop_pattern(z_step/2, z_step, body_h + top_h, 0);
        loop_pattern(z_step,   z_step, body_h + top_h, ang_step/2);
      }
      keepout_volumes();
    }
  }
  
  
  // ===================== STACKING PROTRUSION (open end) =====================
  // Drops 3mm below the body and nests into the ring below it.
  stack_h   = 6;        // how far it extends down
  stack_clr = 0.3;      // clearance so it slips into the ring below

  // protrusion ring
  translate([0, 0, -stack_h])
    difference() {
      cylinder(h = stack_h, d = od - 2*wall - 2*stack_clr);
      cylinder(h = stack_h, d = od - 2*wall - 2*stack_clr - 2*wall);
    }

  // connecting flange: bridges the protrusion to the body wall at z=0
  translate([0, 0, -0.01])
    difference() {
      cylinder(h = 0.5, d = od);
      cylinder(h = 0.5, d = od - 2*wall - 2*stack_clr - 2*wall);
    }
}
