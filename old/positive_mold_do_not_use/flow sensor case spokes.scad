    // Inner ring (5mm to 10mm diameter)
    difference() {
        cylinder(h=10, d=19.5);
        cylinder(h=10, d=16);
    }

    
    // Connecting spokes
    for(i = [0:180:359]) {
        rotate([0,0,i]) {
            translate([8,-2.5,0]) {
                cube([17.5, 5, 5]);
            }
        }
    }