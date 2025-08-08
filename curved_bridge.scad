include <BOSL2/std.scad>

/* [Bridge] */
bridge_height = 120;

grade = -4;
radius = 150;
angle = 45;
straight = false;

grade_angle = atan(grade / 1000);
turn_sign = 1;
curve_radius = radius;


arch_length = radius * angle * PI / 180.0;
pillar_thickness = 20;
hole_radius = (arch_length - pillar_thickness) / 2;

top_thickness = 15;

pillar_height = bridge_height - top_thickness - hole_radius;


/* [Track] */
track_width = 26;

$fn = 90;

function bridge_bend(c) = vnf_bend(skew(c, szx=grade/100.0), r=radius, axis="Z");
module bridge_poly(c) {
    vnf_polyhedron(bridge_bend(c));
}

module bridge_hull() {
    c = back(radius-track_width/2, cube([arch_length, track_width, bridge_height]));
    bridge_poly(c);
}

module bridge_hole_top() {
    c = up(pillar_height, right(arch_length/2, back(radius+track_width/2+1, xrot(90, cylinder(h=track_width+2, r=hole_radius)))));
    bridge_poly(c);
}

module bridge_hole_lower() {
    c = right(pillar_thickness/2, back(radius-track_width/2-1, cube([2*hole_radius, track_width+2, pillar_height])));
    bridge_poly(c);
}

module bridge() {
    // Main body
    difference() {
        bridge_hull();
        bridge_hole_top();
        bridge_hole_lower();
    }
    
    // Pillar side bricks
    color("red") {
        for (i = [0:10]) {
            bridge_translate([0.25, track_width/2+0.5, i*5]) {
                cube([6, 3, 2]);
            }
            bridge_translate([7.25, track_width/2+0.5, i*5]) {
                cube([2.75, 3, 2]);
            }
            bridge_translate([0.0, track_width/2+0.5, i*5 + 2.5]) {
                cube([3, 3, 2]);
            }
            bridge_translate([3.75, track_width/2+0.5, i*5 + 2.5]) {
                cube([6, 3, 2]);
            }
        }
    }  
}

module bridges(n=1) {
    union() {
    for (i=[0:n-1]) {
        up(i*grade/100.0*arch_length)
            zrot(-i*angle)
                bridge();
    }
    }
}

bridges();

module bridge_translate(pos, do_rotate=true, do_scale=true) {
    if (straight) {
        translate(pos) children();
    } else {
        x = pos[0] * turn_sign;
        point_angle = -x / curve_radius * 180.0 / PI;
        point_radius = curve_radius - pos[1];
        
        tunnel_pos = [
            -point_radius * sin(point_angle),
            point_radius * cos(point_angle),
            pos[2] + turn_sign * grade/100 * x,
        ];
        
        // Bricks on the inside have to be shorter than the bricks on the outside
        // so that the same number of bricks can fill the wall on both sides
        sf = do_scale ? point_radius/curve_radius : 1;
        scale_factor = [1, sf, 1];
                
        translate(tunnel_pos) zrot(point_angle) xrot(do_rotate ? turn_sign * grade_angle : 0) scale(scale_factor) children();
    }
}

module bridge_translate_direct(pos) {
    bridge_translate(pos, do_rotate=false, do_scale=false) children();
}
