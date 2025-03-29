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

module wagon(extra_width=0) {
    up(wheels_height) {
        // Wagon body
        cuboid([wagon_width+extra_width, wagon_length, wagon_height], chamfer=wagon_top_chamfer, edges=[TOP+RIGHT,TOP+LEFT], anchor=BOTTOM);
        
        // Wheels
        ydistribute(wheel_base) {
            cuboid([wheels_width+extra_width, wheels_length, wheels_height], anchor=TOP);
            cuboid([wheels_width+extra_width, wheels_length, wheels_height], anchor=TOP);
        }
    }
}

function extra_width_space(radius) = radius - sqrt(radius*radius - wheel_base*wheel_base/4);

module wagon_with_extra_space(radius=0) {
    extra_width = radius == 0 ? 0 : extra_width_space(radius);
    wagon(extra_width);
} 

ydistribute(120) {
    wagon_with_extra_space();
    wagon_with_extra_space(150);
}