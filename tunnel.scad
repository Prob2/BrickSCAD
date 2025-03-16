include <BOSL2/std.scad>;
include <brick.scad>;
use <wall.scad>;
use <unitrack.scad>;

tunnel_length = 128;
tunnel_radius = 18;
side_width = 13;
side_height = 24;

$fn=90;

module chamfered_cut_cylinder(r, h) {
    cylinder(h=h+2*brick_chamfer, r=r, center=true);
    
    up(h/2 + 1*brick_chamfer)
        cylinder(h=4*brick_chamfer, r1=r, r2=r+4*brick_chamfer, center=true);
}

module inner_side_wall(floor_elevation, tunnel_length, side_height, side=1) {
    mortar_offset = -side*(brick_width/2-brick_depth-1);
    up(floor_elevation) {
        brick_wall(tunnel_length, side_height-floor_elevation, open=true, invert_odd=true);
        translate([tunnel_length/2-brick_width-1, mortar_offset, (side_height-floor_elevation)/2]) {
            cube([tunnel_length, 1, side_height-floor_elevation], center=true);
        }
    }
    
    left(brick_width+1)
    back(mortar_offset) {
        cube([brick_width, 1, brick_height]);
        up(floor_elevation/2) {
            cube([brick_length, 1, brick_height]);
        }
    }
}

module tunnel_entrance(radius, side_width, side_height, tunnel_length) {
    width = 2*radius + 2*side_width;
    
    floor_elevation = 2 * brick_height;
    
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
    
    translate([-radius-brick_width/2, brick_length-brick_width/2, 0]) {
        zrot(90) {
            inner_side_wall(floor_elevation, tunnel_length, side_height, 1);
        }
    }
    translate([radius+brick_width/2, brick_length-brick_width/2, 0]) {
        zrot(90) {
            inner_side_wall(floor_elevation, tunnel_length, side_height, -1);
        }
    }

    // Mortar
    fwd(brick_width/2-brick_depth-1)
    difference() {
        up((side_height + 30)/2) {
            cube([width, 1, side_height+30], center=true);
        }
        up(side_height/2) {
            cube([2*radius+2*brick_gap, 2, side_height], center=true);
        }
        up(side_height) {
            xrot(90)
                cylinder(h=2, r=radius+brick_gap, center=true);
        }
    }
    
    // Tunnel Roof Bricks, 1, 
    brick_roof_radius = radius + brick_width/2;
    back(brick_length-brick_width/2)
    left(brick_roof_radius)
    up(side_height) {
        zrot(90)
        brick_wall(tunnel_length, brick_roof_radius*PI, radius=brick_roof_radius, open=true, invert_odd=true);
    }
    
    // Tunnel Roof Mortar
    roof_radius = radius+brick_depth+brick_gap/2;
    fwd(brick_width/2-1)
    up(side_height)
    xrot(-90)
    difference() {
        cylinder(r=roof_radius+1, h=tunnel_length);
        down(1)
            cylinder(r=roof_radius, h=tunnel_length+2);
        up(tunnel_length/2+2)
        back(roof_radius+2)
        cube([2*roof_radius+4, 2*roof_radius+4, tunnel_length+4], center=true);
    }
}

module tunnel_entrance_envelope(radius, side_width, side_height, tunnel_length) {
    width = 2*radius + 2*side_width;
    height = side_height + 30;
    brick_depth = brick_gap/2;
    roof_radius = radius+brick_depth+brick_gap/2;

    // Face
    fwd(brick_width/2) {
        up(height/2)
        cube([2*tunnel_radius + 2*side_width, 3, height], center=true);
    }
    
    // Tunnel
    fwd(brick_width)
    up(side_height)
    xrot(-90) {
        cylinder(r=roof_radius+1, h=tunnel_length+2*brick_length);
    }
    up(side_height/2)
    back(tunnel_length/2+brick_length-brick_width)
    cube([2*roof_radius+2, tunnel_length+2*brick_length, side_height], center=true);
}

intersection() {
    tunnel_entrance(tunnel_radius, side_width, side_height, tunnel_length);
    tunnel_entrance_envelope(tunnel_radius, side_width, side_height, tunnel_length);
}

zrot(180)
xrot(90)
unitrack(tunnel_length, clearance=0);
