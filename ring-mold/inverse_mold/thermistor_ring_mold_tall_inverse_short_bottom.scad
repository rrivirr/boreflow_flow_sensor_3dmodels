difference()
{
    translate([0,0,6]) {
        cube([80, 80, 25], center=true);
    }
    // thing being subtracted
    union() {
        difference()
        {
            difference()
            {
                cylinder(h=15.92, r1=35, r2=35, center=true);
                translate([0,0,14.5]) {
                    difference(){
                        difference()
                        {
                            cylinder(30, r1=25.4, r2=25.4, center=true);
                            cylinder(60, r1=14.2, r2=14.2, center=true);
                        }
                        translate([0,0,-12.5])
                            cylinder(2, r1=15.5, r2=15.5, center=true);
                        
                        translate([0,0,-8.9])
                            cylinder(2.2, r1=15.5, r2=15.5, center=true);
                        
                    }
                }
            }
        }
        // extend the r=14.5 hole 5mm above the r=30 cylinder top
        translate([0,0,5.46])
            cylinder(h=5, r=14.5);
    }
}