include <BOSL2/std.scad>

/* [Brick parameters] */
brick_length = 6;
brick_width = 4;
brick_height = 2.5;

brick_randomness = 0.2;
brick_gap = 0.8;
brick_chamfer = 0.2;
brick_depth = 0.4;

/* [Tunnel roof] */
// Tunnel radius [mm]
tunnel_radius = 18;
// Tunnel side height [mm]
side_height = 22;

/* [Tunnel floor] */
floor_side_wall_height = 6;
floor_side_support_height = 8;
floor_ballast_height = 4;

/* [Track curve] */

// Track curve radius
straight = false;
curve_radius = 150; // [150, 183, 216, 249, 282, 315, 348]
curve_angle = 15; // [15, 22.5, 30, 45, 60, 75, 90]
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
brick_tunnel_radius = tunnel_radius + brick_width/2 - brick_gap/2 - brick_depth;

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
        [tr, side_height],
        for (a = [180:-step:0]) [-tr * cos(a), side_height + tr * sin(a)],
        [-tr, side_height],
        [-tr, 0],
    ];

function floor_profile() = 
    let(r = tunnel_radius, t = thickness)
    [
        [-r-2*t, 0],
        [-r-2*t, floor_side_support_height],
        [-r-t, floor_side_support_height],
        [-r-t, floor_side_wall_height],
        [-r, floor_side_wall_height],
        [-r, floor_ballast_height],
        [-floor_top_hole_width/2, floor_ballast_height],
        [-track_hole_width/2, t],
        [track_hole_width/2, t],
        [floor_top_hole_width/2, floor_ballast_height],
        [r, floor_ballast_height],
        [r, floor_side_wall_height],
        [r+t, floor_side_wall_height],
        [r+t, floor_side_support_height],
        [r+2*t, floor_side_support_height],
        [r+2*t, 0],
    ];

module tunnel_sweep(profile) {
    if (straight) {
        back(straight_track_length * (left ? 1 : 0))
        xrot(90)
        linear_sweep(profile, straight_track_length);
    } else if (curve_height > 0) {
        left(curve_radius)
        up(curve_height/2)
        spiral_sweep(profile, r=curve_radius, turns = turns * turn_sign, h=curve_height, $fn = 90);
    } else if (curve_radius != 0) {
        left(curve_radius)
        zrot(curve_angle * (left ? 0 : -1))
        rotate_sweep(right(curve_radius, profile), angle=curve_angle, $fn=90);
    }
}

module tunnel_translate(pos) {
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
        sf = point_radius/curve_radius;
        scale_factor = [1, sf, 1];
                
        translate(tunnel_pos) zrot(point_angle) xrot(turn_sign * grade_angle) scale(scale_factor) children();
    }
}

module brick(brick_length = brick_length) {
    cuboid([brick_length-brick_gap, brick_width-brick_gap, brick_height-brick_gap], chamfer=brick_chamfer);
}

module side_wall(x) {
    row_count = round(side_wall_height / brick_height);
    for (i = [0:row_count-1]) {
        tunnel_brick_row(x, i%2==0 ? brick_row_offset : 0, i * brick_height);
    }
}

module tunnel() {
    profile = tunnel_profile();
    tunnel_sweep(profile);
    side_wall(-brick_tunnel_radius);
    side_wall(brick_tunnel_radius);    
}

module envelope() {
    profile = tunnel_envelope_profile();
    tunnel_sweep(profile);
}

intersection() {
    tunnel();
    envelope();
}

down(12) {
    profile = floor_profile();
    tunnel_sweep(profile);
}

module tunnel_brick_row(x=0, offset=0, z=0) {
    brick_count = round(track_length / brick_length);
    brick_length = track_length / brick_count;

    for (i = [1:brick_count]) {
        tunnel_translate([x, offset + (i-0.5) * brick_length, z + brick_height/2-brick_gap/2])
            zrot(90)
                brick(brick_length);
    }
}
