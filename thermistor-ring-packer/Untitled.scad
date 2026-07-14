difference() {
    // Main hollow cylinder
    difference() {
        cylinder(h=40, d=52);
        cylinder(h=40, d=46);
    }
    
    // Holes spaced every 10mm vertically and horizontally
    for(z = [5:10:35]) {
        for(angle = [0:30:330]) {
            rotate([0,0,angle]) {
                translate([24.5,0,z]) {
                    rotate([0,90,0]) {
                        cylinder(h=10, d=6, center=true);
                    }
                }
            }
        }
    }
}