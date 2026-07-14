union() {
translate([0,0,40]) {    
    difference(){
    difference() {
        cylinder(h=5, d=49);
        cylinder(h=5, d=21.1);
    }
    translate([12,-6.5,0]){
        cube([9,13,5]);
//        cylinder(h=5,d=10);
}
}
    
}

    // Outer ring (42mm to 52mm diameter, now chnaged to 46 to 49mm)
difference() {
    // Main hollow cylinder
    difference() {
        cylinder(h=40, d=49);
        cylinder(h=40, d=46);
    }
    
    // Holes spaced every 10mm vertically and horizontally
     // Holes spaced every 10mm vertically and horizontally
    for(z = [5:5:35]) {
        for(angle = [0:10:350]) {
            rotate([0,0,angle]) {
                translate([24.5,0,z]) {
                    rotate([0,90,0]) {
                        cylinder(h=10, d=2, center=true);
                    }
                }
            }
        }
    }
    
    for(z = [2.5:5:35]) {
        for(angle = [5:10:355]) {
            rotate([0,0,angle]) {
                translate([24.5,0,z]) {
                    rotate([0,90,0]) {
                        cylinder(h=10, d=2, center=true);
                    }
                }
            }
        }
    }    
 
 
    // Connecting spokes
    for(i = [0:180:359]) {
        rotate([0,0,i]) {
            translate([8,-2.5,0]) {
                cube([17.5, 5, 5]);
            }
        }
    }    
    
}


    

}