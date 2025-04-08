include <BOSL2/std.scad>

/* [Included components] */
Include_tunnel = true;
Include_floor = true;
Include_portal = true;
Include_portal_frame = true;
Include_separate_frame = true;

/* [Brick parameters] */
brick_length = 5.6;
brick_width = 4;
brick_height = 2.25; // [2:0.05:4]

brick_randomness = 0.2;
brick_gap = 0.8;
brick_chamfer = 0.2;
brick_depth = 0.6;

/* [Tunnel roof] */
// Tunnel radius [mm]
tunnel_radius = 16;
// Tunnel side height [mm]
side_height = 23.8;
tunnel_roof_step = 5;

/* [Tunnel floor] */
floor_side_wall_height = 6;
floor_side_support_height = 8;
floor_ballast_height = 4;

floor_off_center = 1;

/* [Tunnel Portal] */
portal_width_left = 10;
portal_width_right = 10;
portal_height_top = 7.5;
portal_chamfer = 10;
portal_frame_depth = 20;

/* [Track curve] */

// Track curve radius
straight = false;
curve_radius = 150; // [150, 183, 216, 249, 282, 315, 348]
curve_angle = 5; // [5, 15, 22.5, 30, 45, 60, 75, 90]
grade_percent = 4.0; // [0.0:0.5:6]
left = false;
straight_track_length = 128;

/* [Common Kato Unitrack sizes] */
track_width = 26;
ballast_width=18.5;
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

portal_radius = tunnel_radius - brick_gap;
portal_width = 2*portal_radius + portal_width_left + portal_width_right;
portal_height = side_height + portal_radius + portal_height_top;
portal_chamfer_size = portal_width + portal_height;

function tunnel_profile(step = 5, wh = side_wall_height) = 
    let (tr = tunnel_radius + thickness)
    [
        [-tunnel_radius, 0],
        [-tunnel_radius, wh],
        for (a = [0:step:180]) [-tunnel_radius * cos(a), wh + tunnel_radius * sin(a)],
        [tunnel_radius, wh],
        [tunnel_radius, 0],
        [tr, 0],
        [tr, wh],
        for (a = [180:-step:0]) [-tr * cos(a), wh + tr * sin(a)],
        [-tr, side_wall_height],
        [-tr, 0],
    ];
    
function tunnel_envelope_profile(step = 5, wh = side_wall_height) = 
    let (tr = tunnel_radius + thickness)
    [
        [tr, 0],
        [tr, wh],
        for (a = [180:-step:0]) [-tr * cos(a), wh + tr * sin(a)],
        [-tr, wh],
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


module brick_base(size, chamfer = brick_chamfer) {
  cuboid(size, chamfer = chamfer);
}

function cut_length(height, angle) = height * tan(angle);

module brick(length = brick_length, width = brick_width, height = brick_height, rf = brick_randomness, radius = 0, gap = brick_gap, chamfer = brick_chamfer, cut_angle=0) {

  r = rands(-rf, rf, 7);
  rrot = rands(-10 * rf, 10 * rf, 3);

  stretch = (radius != 0) ? (height / radius / PI) : 0;
    
  cut_factor = tan(cut_angle);
  cut_x = cut_length(height-gap, cut_angle);
    
  if (abs(cut_x) > length - gap - rf - 2*chamfer) {
      color("red") {
          cube(1, 1, 1);
      }
  } else {

      size = [length - gap + r[0] - abs(cut_x), width - gap + r[1], height - gap + r[2] - stretch * length];

      rotate(rrot) {
        hull() {
          left(cut_x/2)
            brick_base(size, chamfer);

          if (radius != 0) {
              up(stretch / 2 * length)
                skew(szx = stretch)
                  brick_base(size, chamfer);
              down(stretch / 2 * length)
                skew(szx = -stretch)
                  brick_base(size, chamfer);
          }
          
          if (cut_angle != 0) {
              right(0)
              skew(sxz = cut_factor)
                brick_base(size, chamfer);          
          }
        }
      }
    }
}

module side_wall(x) {
    row_count = round(side_wall_height / brick_height);
    for (i = [0:row_count-1]) {
        tunnel_brick_row(x, i%2==1 ? brick_row_offset : 0, i * brick_height);
        
        end_x = x - sign(x) * (brick_wall_offset - thickness/2);
        end_y = (i%2==1) ? track_length : 0;
        tunnel_translate_direct([0, end_y, 0]) {
            brick_end_sweep(-end_x, (i+0.5) * brick_height);
        }
    }
}

module front_brick_row(x, is_odd) {
    brick_count = round((x + brick_row_offset) / brick_length);
}

module front_wall(x) {
    row_count = round(side_wall_height / brick_height);
    for (i = [0:row_count-1]) {
        translate([0, 0, i*brick_height]) {
            front_brick_row(x, i%2==0 ? brick_row_offset : 0, i * brick_height);
        }
    }
}

arch_length = PI * tunnel_radius;
// Rounding it after dividing by 2 ensures there is always a brick at the very top.
// Dividing it by 4 makes sure the brick on top is vertical
roof_row_count = round(arch_length / brick_height / 4) * 4;

function roof_angle(i) = (i+0.5) * 180 / (roof_row_count+1);

module brick_roof(odd=false) {
    for (i = [0:roof_row_count]) {
        angle = roof_angle(i);
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
    
    side_row_count = round(side_wall_height / brick_height);
    brick_roof(odd=(side_row_count % 2) == 0);
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

if (Include_tunnel) {
    intersection() {
        tunnel();
        envelope();
    }
}

if (Include_floor) {
    down(12) {
        profile = floor_profile();
        tunnel_sweep(profile);
    }
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

module chamfered_cut_cylinder(r, h) {
    cylinder(h=h+2*brick_chamfer, r=r, center=true);
    
    up(h/2 + 1*brick_chamfer)
        cylinder(h=4*brick_chamfer, r1=r, r2=r+4*brick_chamfer, center=true);
}

module tunnel_entrance() {
    radius = tunnel_radius - brick_gap;
    width = 2*radius + portal_width_left + portal_width_right;
    height = side_height + radius + portal_height_top;
        
    z_offset = floor_side_wall_height - 2 * brick_height;
    up(z_offset)
    left(radius) {
        mirror([1, 0, 0])
            brick_wall(portal_width_left, side_height-z_offset);
    }
    up(z_offset)
    right(radius) {
        brick_wall(portal_width_right, side_height-z_offset);
    }
    
    up(side_height) {
        brick_arch(radius+brick_gap, odd=true);
        
        difference() {
        left(radius + portal_width_left) {
            brick_wall(width, tunnel_radius + portal_height_top, symm=true);
        }
        xrot(90) {
            chamfered_cut_cylinder(r=radius+brick_length+brick_gap/2, h=brick_width-brick_gap);
        }
        }
    }

    // Mortar
    fwd(brick_width/2-brick_depth-thickness)
    difference() {
        up(height/2) {
            cube([width, thickness, height], center=true);
        }
        back(1)
        xrot(90)
        linear_sweep(tunnel_envelope_profile(wh = side_height), 3);
    }
    back(brick_length-2)
    xrot(90)
    linear_sweep(tunnel_profile(wh = side_height), brick_length-1);
}

module mirror_if_left(plane=[0, 1, 0]) {
    if (left) {
        mirror(plane) children();
    } else {
        children();
    }
}

module xz_translate(distance, left=true) {
    translate([left ? distance/sqrt(2) : -distance/sqrt(2), 0, distance/sqrt(2)]) children();
}

if (Include_portal) {
    mirror_if_left() {
        mirror([0, 1, 0])
        fwd(brick_length-brick_width)
        down(floor_side_wall_height) {
        difference() {
        intersection() {
            tunnel_entrance();
            tunnel_entrance_envelope();
            }
            
            fwd(brick_width/2)
            up(portal_height)
            left(portal_radius+portal_width_left)
            xz_translate(portal_chamfer_size/2 - portal_chamfer, left=false)
            entrance_chamfer_cut();
            
            fwd(brick_width/2)
            up(portal_height)
            right(portal_radius+portal_width_right)
            xz_translate(portal_chamfer_size/2 - portal_chamfer, left=true)
            entrance_chamfer_cut();
        }
        }
    }
}

module portal_frame(include_bottom=false) {
    radius = tunnel_radius - brick_gap;
    height = side_height+radius+portal_height_top;
    width = 2*radius + portal_width_left + portal_width_right;
    chamfer_length = portal_chamfer * sqrt(2);

    mirror_if_left()
    fwd(portal_frame_depth - brick_width/2)
    down(floor_side_wall_height) {
        left(radius + portal_width_left) {
            cube([thickness, portal_frame_depth, height-chamfer_length]);
            
            if (portal_chamfer > 0)
            up(height-chamfer_length)
            yrot(45)
            cube([thickness, portal_frame_depth, 2*portal_chamfer]);
        }
        right(radius + portal_width_right - thickness) {
            cube([thickness, portal_frame_depth, height-chamfer_length]);
            
            if (portal_chamfer > 0)
            up(height-chamfer_length)
            right(thickness)
            yrot(-45)
            left(thickness)
            cube([thickness, portal_frame_depth, 2*portal_chamfer]);
        }
        left(radius + portal_width_left - chamfer_length) {
            up(height-thickness)
            cube([width-2*chamfer_length, portal_frame_depth, thickness]);
        }
        if (include_bottom) {
            left(radius + portal_width_left) {
                cube([width, portal_frame_depth, thickness]);
            }
        }
    }
}

if (Include_portal_frame) {
    portal_frame(include_bottom=false);
}

if (Include_separate_frame) {
    right(2*tunnel_radius + portal_width_left + portal_width_right + 20)
    portal_frame(include_bottom=true);
}


module brick_arch(inner_radius, alternating = true, odd=false) {
  radius = tunnel_radius - brick_gap + brick_length/2;

  hl = brick_length / 2;
  ql = brick_length / 4;

  for(i = [0:roof_row_count]) {
    angle = roof_angle(i);
    yrot(-angle)
      right(radius) {
        if (!alternating || (i % 2 == 0) == odd) {
          brick(radius = radius, length = brick_length, height = brick_height);
        } else {
          back(brick_length / 2 - brick_width / 2) {
            left(ql)
              brick(radius = radius - ql, length = hl, height = brick_height * (radius - ql) / radius, width = brick_length);
            right(ql)
              brick(radius = radius + ql, length = hl, height = brick_height * (radius + ql) / radius, width = brick_length);
          }
        }
      }
  }
}


function flatten(l) =
  [
    for (a = l)
      for (b = a)
        b
  ];

function row_brick_length(row_length) =
  let (brick_count = round(row_length / brick_length))
    let (brick_length = row_length / brick_count)
      [brick_count, brick_length];

function row_points(c, l, e, h, is_odd) =
  let (lw = (brick_length - brick_width) / 2)
    is_odd ? [
      [brick_width / 2, lw, e + h / 2, brick_width, brick_length, h], 
      if (c > 0)
        for (i = [1:c])
          [brick_width - l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
    ] : [
      if (c > 0)
        for (i = [1:c])
          [-l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
      [(c) * l + brick_width / 2, lw, e + h / 2, brick_width, brick_length, h], 
    ];

function row_points_open(c, l, e, h, is_odd) =
  let (s = is_odd ? brick_width - brick_length : 0)
    [for (i = [0:c-1])
      [s + l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
    ];

function row_points_symm(c, l, e, h, is_odd) =
  let (lw = (l - brick_width) / 2)
    is_odd ? [
      [l / 4, lw, e + h / 2, l / 2, l, h], 
      if (c >= 1)
        for (i = [1:c - 1])
          [i * l, 0, e + h / 2, l, brick_width, h], 
      [(c) * l - l / 4, lw, e + h / 2, l / 2, l, h], 
    ] : [
      if (c >= 1)
        for (i = [1:c])
          [-l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
    ];

function wall_points(length, height, invert_odd) =
  let (whole_brick_length = length - brick_width)
    let (whole_brick_count = round(whole_brick_length / brick_length))
      let (i_brick_length = whole_brick_length / whole_brick_count)
        let (row_brick_count = whole_brick_count)
          let (row_count = round(height / brick_height))
            let (i_brick_height = height / row_count)
              flatten([
                for (r = [0:row_count - 1])
                  row_points(row_brick_count, i_brick_length, r * brick_height, brick_height, (r % 2 == 0) == invert_odd), 
              ]);

function wall_points_open(length, height, invert_odd) =
  let (whole_brick_length = length)
    let (whole_brick_count = round(whole_brick_length / brick_length))
      let (i_brick_length = whole_brick_length / whole_brick_count)
        let (row_brick_count = whole_brick_count)
          let (row_count = round(height / brick_height))
            let (i_brick_height = height / row_count)
              flatten([
                for (r = [0:row_count - 1])
                  row_points_open(row_brick_count, i_brick_length, r * brick_height, brick_height, (r % 2 == 0) == invert_odd), 
              ]);

function wall_points_symm(length, height, invert_odd) =
  let (row_brick_count = round(length / brick_length))
    let (i_brick_length = length / row_brick_count)
      let (row_count = round(height / brick_height))
        let (i_brick_height = height / row_count)
          flatten([
            for (r = [0:row_count - 1])
              row_points_symm(row_brick_count, i_brick_length, r * brick_height, brick_height, (r % 2 == 0) == invert_odd), 
          ]);

          
module brick_wall(length, height, symm = false, holes=[], invert_odd=false, open=false, radius=0) {
  points = (symm) ? wall_points_symm(length, height, invert_odd) : open ? wall_points_open(length, height, invert_odd) : wall_points(length, height, invert_odd);
  for(p = points) {
    pos = [p[0], p[1], p[2]];
    translate(pos) {
      angle_cut = (len(holes) > 0) ? brick_cut_angle(pos, holes[0]) : [true, 0, 0];
      if (angle_cut[0]) {
        brick(length = p[3], width = p[4], height = p[5], cut_angle=angle_cut[1]);
    }}
  }
}


module tunnel_entrance_envelope() {
    radius = tunnel_radius - brick_gap;
    width = 2*radius + portal_width_left + portal_width_right;
    height = side_height + radius + portal_height_top;
         
    // Mortar
    fwd(brick_width/2-thickness)
    union() {
        up(height/2) {
            cube([width, thickness+2*brick_depth, height], center=true);
        }
        back(brick_length)
        up(floor_side_wall_height)
        xrot(90)
        linear_sweep(tunnel_envelope_profile(wh = side_wall_height), brick_length);
        
        back(brick_width/2+thickness)
        xrot(90)
        linear_sweep(tunnel_envelope_profile(wh = side_height), brick_width);
    }
}

module entrance_chamfer_cut() {
color("blue")
            back(brick_depth+thickness/2 - brick_depth/2 - brick_chamfer)
yrot(45)
xrot(90)
    cuboid(
    [portal_chamfer_size+brick_gap,portal_chamfer_size+brick_gap,brick_depth+2*brick_chamfer], chamfer=-3*brick_chamfer, edges=[TOP]);
    
    color("red")
            back(portal_frame_depth/2+brick_depth+thickness/2)
yrot(45)
xrot(90)
    cuboid(
    [portal_chamfer_size,portal_chamfer_size,portal_frame_depth]);
    
}
