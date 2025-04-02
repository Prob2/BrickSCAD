include <BOSL2/std.scad>

// poly = [[-10,0], [-3,-5], [3,-5], [10,0], [0,-30]];
// spiral_sweep(poly, h=200, r=50, turns=3, $fn=90);

tunnel_radius = 18;
side_height = 22;
thickness = 1;

function tunnel_profile(r, h, t, step = 5) = 
    let (tr = tunnel_radius + thickness)
    [
        [-tunnel_radius, 0],
        [-tunnel_radius, side_height],
        for (a = [0:step:180]) [-tunnel_radius * cos(a), side_height + tunnel_radius * sin(a)],
        [tunnel_radius, side_height],
        [tunnel_radius, 0],
        [tr, 0],
        [tr, side_height],
        for (a = [180:-step:0]) [-tr * cos(a), side_height + tr * sin(a)],
        [-tr, side_height],
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

function floor_profile(r, t) = 
    let(track_width = 25.5, ballast_width=18, ballast_height=5.1, clearance=0.15)
    let(ballast_grade = (track_width-ballast_width) /2 / ballast_height)
    let(track_hole_width = track_width+2*clearance)
    let(full_width = 2*r+4*t)
    let(side_wall_height = 6)
    let(side_support_height = 8)
    let(ballast_height = 4)
    let(top_hole_width = track_hole_width - ballast_grade * ballast_height)
    [
        [-r-2*t, 0],
        [-r-2*t, side_support_height],
        [-r-t, side_support_height],
        [-r-t, side_wall_height],
        [-r, side_wall_height],
        [-r, ballast_height],
        [-top_hole_width/2, ballast_height],
        [-track_hole_width/2, t],
        [track_hole_width/2, t],
        [top_hole_width/2, ballast_height],
        [r, ballast_height],
        [r, side_wall_height],
        [r+t, side_wall_height],
        [r+t, side_support_height],
        [r+2*t, side_support_height],
        [r+2*t, 0],
    ];

curve_radius = 150;
curve_angle = 75;
grade = 0.04;
left = false;
turn_sign = left ? 1 : -1;

turns = curve_angle / 360;
curve_length = curve_radius * curve_angle * PI / 180.0;
curve_height = curve_length * grade;

echo(curve_height);

module tunnel_sweep(profile) {
    up(curve_height/2)
    spiral_sweep(profile, r=curve_radius, turns = turns * turn_sign, h=curve_height, $fn = 360);
}

module tunnel() {
    profile = tunnel_profile(tunnel_radius, side_height, thickness);
    tunnel_sweep(profile);
}

module envelope() {
    profile = tunnel_envelope_profile(tunnel_radius, side_height, thickness);
    tunnel_sweep(profile);
}

tunnel();

down(12) {
    profile = floor_profile(tunnel_radius, thickness);
    tunnel_sweep(profile);
}