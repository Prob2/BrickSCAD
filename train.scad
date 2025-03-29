include <BOSL2/std.scad>;
include <brick.scad>;
use <wall.scad>;
use <unitrack.scad>;

wagon_length = 100;
wagon_height = 18;
wagon_width = 13;
wagon_top_chamfer = 3;

wheels_width = 10;
wheels_length = 15;
wheels_height = 4;

wheel_base = 80;

module wagon() {
    up(wheels_height) {
        // Wagon body
        cuboid([wagon_width, wagon_length, wagon_height], chamfer=wagon_top_chamfer, edges=[TOP+RIGHT,TOP+LEFT], anchor=BOTTOM);
        
        // Wheels
        ydistribute(wheel_base) {
            cuboid([wheels_width, wheels_length, wheels_height], anchor=TOP);
            cuboid([wheels_width, wheels_length, wheels_height], anchor=TOP);
        }
    }
}

wagon();