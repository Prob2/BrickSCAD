include <BOSL2/std.scad>

/* [Brick parameters] */
brick_length = 6;
brick_width = 4;
brick_height = 2.4; // [2:0.05:4]

brick_randomness = 0.2;
brick_gap = 0.8;
brick_chamfer = 0.2;
brick_depth = 0.6;

/* [Tunnel roof] */
// Tunnel radius [mm]
tunnel_radius = 17;
// Tunnel side height [mm]
side_height = 24;

/* [Tunnel floor] */
floor_side_wall_height = 6;
floor_side_support_height = 8;
floor_ballast_height = 4;

floor_off_center = 1;

/* [Track curve] */

// Track curve radius
straight = false;
curve_radius = 150; // [150, 183, 216, 249, 282, 315, 348]
curve_angle = 15; // [5, 15, 22.5, 30, 45, 60, 75, 90]
grade_percent = 4.0; // [0.0:0.5:6]
left = false;
straight_track_length = 128;

/* [Common Kato Unitrack sizes] */
track_width = 25.5;
ballast_width=18;
ballast_height=5.1;

/* [3D printing parameters] */
// Tunnel wall thickness [mm]
thickness = 1;
// Clearance between separate printed parts [mm]
clearance = 0.15;

/* [Hidden] */
grade = grade_percent / 100.0;
turn_sign = left ? 1 : -1;
turns = curve_angle / 360;
curve_length = curve_radius * curve_angle * PI / 180.0;
curve_height = curve_length * grade;
grade_angle = atan(grade);

ballast_grade = (track_width-ballast_width) / 2 / ballast_height;
track_hole_width = track_width+2*clearance;
floor_top_hole_width = track_hole_width - ballast_grade * ballast_height;

track_length = straight ? straight_track_length : curve_length;
side_wall_height = side_height - floor_side_wall_height;

brick_row_offset = brick_length - brick_width;
brick_wall_offset = brick_width/2 - brick_gap/2 - brick_depth;
brick_tunnel_radius = tunnel_radius + brick_wall_offset;

envelope_extra_angle = 5 * turn_sign;
envelope_extra_length = curve_radius * envelope_extra_angle * PI / 180.0;
envelope_extra_height = envelope_extra_length * grade * turn_sign;

function tunnel_profile(step = 5) = 
    let (tr = tunnel_radius + thickness)
    [
        [-tunnel_radius, 0],
        [-tunnel_radius, side_wall_height],
        for (a = [0:step:180]) [-tunnel_radius * cos(a), side_wall_height + tunnel_radius * sin(a)],
        [tunnel_radius, side_wall_height],
        [tunnel_radius, 0],
        [tr, 0],
        [tr, side_wall_height],
        for (a = [180:-step:0]) [-tr * cos(a), side_wall_height + tr * sin(a)],
        [-tr, side_wall_height],
        [-tr, 0],
    ];
    
function tunnel_envelope_profile(r, h, t, step = 5) = 
    let (tr = tunnel_radius + thickness)
    [
        [tr, 0],
        [tr, side_wall_height],
        for (a = [180:-step:0]) [-tr * cos(a), side_wall_height + tr * sin(a)],
        [-tr, side_wall_height],
        [-tr, 0],
    ];
    
function tunnel_inner_envelope_profile(r, h, t, step = 5) = 
    let (tr = tunnel_radius - clearance)
    [
        [tr, 0],
        [tr, side_wall_height],
        for (a = [180:-step:0]) [-tr * cos(a), side_wall_height + tr * sin(a)],
        [-tr, side_wall_height],
        [-tr, 0],
    ];

function floor_profile() = 
    let(r = tunnel_radius, t = thickness, oc = floor_off_center)
    [
        [-r-2*t, 0],
        [-r-2*t, floor_side_support_height],
        [-r-t, floor_side_support_height],
        [-r-t, floor_side_wall_height],
        [-r, floor_side_wall_height],
        [-r, floor_ballast_height],
        [-floor_top_hole_width/2+oc, floor_ballast_height],
        [-track_hole_width/2+oc, t],
        [track_hole_width/2+oc, t],
        [floor_top_hole_width/2+oc, floor_ballast_height],
        [r, floor_ballast_height],
        [r, floor_side_wall_height],
        [r+t, floor_side_wall_height],
        [r+t, floor_side_support_height],
        [r+2*t, floor_side_support_height],
        [r+2*t, 0],
    ];
    
module segment_sweep(profile, length) {
    factor = length / track_length;
    if (straight) {
        back(length * (left ? 1 : 0))
        xrot(90)
        linear_sweep(profile, straight_track_length*factor);
    } else if (curve_height > 0) {
        left(curve_radius)
        up(curve_height*factor/2)
        spiral_sweep(profile, r=curve_radius, turns = turns * turn_sign * factor, h=curve_height * factor, $fn = 90);
    } else if (curve_radius != 0) {
        left(curve_radius)
        zrot(curve_angle * (left ? 0 : -1) * factor)
        rotate_sweep(right(curve_radius, profile), angle=curve_angle * factor, $fn=90);
    }
}

module tunnel_sweep(profile, extra_length=0) {
    segment_sweep(profile, track_length + extra_length);
}

module brick_end_sweep(x=0, z=0, angle=0) {
    length = brick_row_offset;
    profile = back(z, right(x, zrot(angle, rect([thickness, brick_height-clearance]))));
    segment_sweep(profile, length);
}

module tunnel_translate(pos, do_rotate=true, do_scale=true) {
    if (straight) {
        translate(pos) children();
    } else {
        y = pos[1] * turn_sign;
        point_angle = y / curve_radius * 180.0 / PI;
        point_radius = curve_radius - pos[0];
        
        tunnel_pos = [
            point_radius * cos(point_angle) - curve_radius,
            point_radius * sin(point_angle),
            pos[2] + turn_sign * grade * y,
        ];
        
        // Bricks on the inside have to be shorter than the bricks on the outside
        // so that the same number of bricks can fill the wall on both sides
        sf = do_scale ? point_radius/curve_radius : 1;
        scale_factor = [1, sf, 1];
                
        translate(tunnel_pos) zrot(point_angle) xrot(do_rotate ? turn_sign * grade_angle : 0) scale(scale_factor) children();
    }
}

module tunnel_translate_direct(pos) {
    tunnel_translate(pos, do_rotate=false, do_scale=false) children();
}

module brick(brick_length = brick_length) {
    cuboid([brick_length-brick_gap, brick_width-brick_gap, brick_height-brick_gap], chamfer=brick_chamfer);
}

module side_wall(x) {
    row_count = round(side_wall_height / brick_height);
    for (i = [0:row_count-1]) {
        tunnel_brick_row(x, i%2==0 ? brick_row_offset : 0, i * brick_height);
        
        end_x = x - sign(x) * (brick_wall_offset - thickness/2);
        end_y = (i%2==0) ? track_length : 0;
        tunnel_translate_direct([0, end_y, 0]) {
            brick_end_sweep(-end_x, (i+0.5) * brick_height);
        }
    }
}

module brick_roof(odd=false) {
    arch_length = PI * tunnel_radius;
    
    // Rounding it after dividing by 2 ensures there is always a brick at the very top.
    // Dividing it by 4 makes sure the brick on top is vertical
    row_count = round(arch_length / brick_height / 4) * 4;
    
    for (i = [0:row_count]) {
        angle = i * 180 / row_count;
        x = -brick_tunnel_radius * cos(angle);
        z = side_wall_height - thickness + brick_tunnel_radius * sin(angle);
        tunnel_brick_row(x, (i%2==1) == odd ? brick_row_offset : 0, z, angle);

        end_radius = brick_tunnel_radius - brick_wall_offset + thickness/2;
        end_x = -end_radius * cos(angle);
        end_y = ((i%2==1) == odd) ? track_length : 0;
        end_z = side_wall_height + end_radius * sin(angle);
        tunnel_translate_direct([0, end_y, 0]) {
            brick_end_sweep(-end_x, end_z, angle);
        }
    }
}

module tunnel() {
    profile = tunnel_profile();
    tunnel_translate_direct([0, brick_row_offset, 0])
        tunnel_sweep(profile, extra_length=-brick_row_offset);
    side_wall(-brick_tunnel_radius);
    side_wall(brick_tunnel_radius);    
    brick_roof(odd=true);
}

module envelope() {
    profile = tunnel_envelope_profile();
    tunnel_sweep(profile, extra_length = brick_row_offset);
    
    /*
    
    inner_profile = tunnel_inner_envelope_profile();
    
    if (straight) {
        back(envelope_extra_angle) tunnel_sweep(inner_profile);        
    } else {
        up(envelope_extra_height)
        left(curve_radius)
        zrot(envelope_extra_angle)
        right(curve_radius)
        tunnel_sweep(inner_profile);
    }
    */
}

intersection() {
    tunnel();
    envelope();
}

// envelope();

down(12) {
    profile = floor_profile();
    tunnel_sweep(profile);
}

module tunnel_brick_row(x=0, offset=0, z=0, angle=0) {
    brick_count = round(track_length / brick_length);
    brick_length = track_length / brick_count;

    for (i = [1:brick_count]) {
        tunnel_translate([x, offset + (i-0.5) * brick_length, z + brick_height/2])
            yrot(straight ? angle : -angle)
            zrot(90)
                brick(brick_length);
    }
}
