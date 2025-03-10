include <BOSL2/std.scad>;
include <brick.scad>;
use <wall.scad>;

module chamfered_cut_cylinder(r, h) {
    cylinder(h=h+2*brick_chamfer, r=r, center=true);
    
    up(h/2 + 1*brick_chamfer)
        cylinder(h=4*brick_chamfer, r1=r, r2=r+4*brick_chamfer, center=true);
}

module tunnel_entrance(radius, side_width, side_height) {
    width = 2*radius + 2*side_width;
    
    left(radius) {
        mirror([1, 0, 0])
            brick_wall(side_width, side_height);
    }
    right(radius) {
        brick_wall(side_width, side_height);
    }
    
    up(side_height) {
        brick_arch(radius);
        
        difference() {        
            left(width/2) {
                brick_wall(width, 30, symm=true, invert_odd=true);
            }
            xrot(90) {
                chamfered_cut_cylinder(r=radius+brick_length+brick_gap/2, h=brick_width-brick_gap);
            }
        }
    }
    
    zrot(90) {
        brick_wall(40, side_height, open=true, invert_odd=true);
    }
}

tunnel_entrance(18, 13, 24);
