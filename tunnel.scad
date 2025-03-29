include <BOSL2/std.scad>;
include <brick.scad>;
use <wall.scad>;
use <unitrack.scad>;

tunnel_length = 32;
tunnel_radius = 18;
side_width = 13;
side_height = 24;

$fn=90;

clearance = 0.15;

module chamfered_cut_cylinder(r, h) {
    cylinder(h=h+2*brick_chamfer, r=r, center=true);
    
    up(h/2 + 1*brick_chamfer)
        cylinder(h=4*brick_chamfer, r1=r, r2=r+4*brick_chamfer, center=true);
}

module inner_side_wall(floor_elevation, tunnel_length, side_height, side=1) {
    wall_length = tunnel_length+brick_length-brick_width/2-brick_gap;
    mortar_offset = -side*(brick_width/2-brick_depth-1);
    up(floor_elevation) {
        brick_wall(tunnel_length, side_height-floor_elevation, open=true, invert_odd=true);
        translate([wall_length/2-brick_width-1, mortar_offset, (side_height-floor_elevation)/2+clearance]) {
            cube([wall_length, 1, side_height-floor_elevation-clearance], center=true);
        }
    }
    
    left(brick_width+1)
    back(mortar_offset-1/2) {
        cube([brick_width-clearance, 1, brick_height+2*clearance]);
        up(floor_elevation/2 + clearance) {
            cube([brick_length-clearance, 1, brick_height]);
        }
    }
}

module segment_side_wall(floor_elevation, tunnel_length, side_height, side=1) {
    wall_offset = brick_length-brick_width/2;
    wall_length = tunnel_length+brick_length-brick_width/2-brick_gap;
    mortar_offset = -side*(brick_width/2-brick_depth-1);
    up(floor_elevation) {
        brick_wall(tunnel_length, side_height-floor_elevation, open=true, invert_odd=true);
        translate([tunnel_length/2-wall_offset/4, mortar_offset, (side_height-floor_elevation)/2+clearance]) {
            cube([tunnel_length-wall_offset/2, 1, side_height-floor_elevation-clearance], center=true);
        }
    }
}

module tunnel_entrance_full(radius, side_width, side_height, tunnel_length) {
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
        cylinder(r=roof_radius+1, h=tunnel_length+brick_length-brick_width/2-brick_gap);
        down(1)
            cylinder(r=roof_radius, h=tunnel_length+brick_length);
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

module tunnel_segment_envelope(radius, side_height, tunnel_length) {
    brick_depth = brick_gap/2;
    roof_radius = radius+brick_depth+brick_gap/2;
    
    // Tunnel
    back(brick_width/2)
    up(side_height)
    xrot(-90) {
        cylinder(r=roof_radius+1, h=tunnel_length+2*brick_length);
    }
    up(side_height/2+brick_height)
    back(tunnel_length/2+brick_length+brick_width/2)
    cube([2*roof_radius+2, tunnel_length+2*brick_length, side_height-2*brick_height], center=true);
}

module tunnel_entrance(tunnel_radius, side_width, side_height, tunnel_length) {
    intersection() {
        tunnel_entrance_full(tunnel_radius, side_width, side_height, tunnel_length);
        tunnel_entrance_envelope(tunnel_radius, side_width, side_height, tunnel_length);
    }
}

module tunnel_floor(tunnel_radius, tunnel_length, height=4) {
    floor_elevation = 2 * brick_height;

    holder_height = 4;
    total_height = floor_elevation + holder_height;
    difference() {
        back(tunnel_length/2)
        up(total_height/2)
        cube([2*tunnel_radius+6, tunnel_length, total_height], center=true);
        back(tunnel_length/2)
        up(total_height/2 + floor_elevation/2 + 1)
        cube([2*tunnel_radius+4, tunnel_length+1, holder_height+2], center=true);
        back(tunnel_length/2)
        up(height+holder_height/2+1)
        cube([2*tunnel_radius, tunnel_length+1, holder_height+2], center=true);
        up(1)
        fwd(1)
        zrot(180)
        xrot(90)
        unitrack(tunnel_length+2, clearance=0.25);
    }
}

module tunnel_segment_full(radius, side_height, tunnel_length) {
    floor_elevation = 2 * brick_height;
    
    translate([-radius-brick_width/2, brick_length-brick_width/2, 0]) {
        zrot(90) {
            segment_side_wall(floor_elevation, tunnel_length, side_height, 1);
        }
    }
    translate([radius+brick_width/2, brick_length-brick_width/2, 0]) {
        zrot(90) {
            segment_side_wall(floor_elevation, tunnel_length, side_height, -1);
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
    wall_offset = brick_length-brick_width/2;
    up(side_height)
    back(wall_offset)
    xrot(-90)
    difference() {
        cylinder(r=roof_radius+1, h=tunnel_length-wall_offset/2);
        down(1)
            cylinder(r=roof_radius, h=tunnel_length+1);
        up(tunnel_length/2+2)
        back(roof_radius+2)
        cube([2*roof_radius+4, 2*roof_radius+4, tunnel_length+4], center=true);
    }
}

module tunnel_segment(tunnel_radius, side_height, tunnel_length) {
    intersection() {
        tunnel_segment_full(tunnel_radius, side_height, tunnel_length);
        tunnel_segment_envelope(tunnel_radius, side_height, tunnel_length);
    }
}


tunnel_entrance(tunnel_radius, side_width, side_height, tunnel_length);

back(tunnel_length + 40) {
    tunnel_segment(tunnel_radius, side_height, tunnel_length);
}

back(brick_length)
down(20)
xdistribute(60) {
    tunnel_floor(tunnel_radius, tunnel_length, 4);
    tunnel_floor(tunnel_radius, tunnel_length, 5);
    tunnel_floor(tunnel_radius, tunnel_length, 6);
}
