include <BOSL2/std.scad>

/* [Bridge] */
bridge_height = 120;

grade = -4;
radius = 150;
angle = 45;
straight = false;

grade_angle = atan(grade / 100);
turn_sign = 1;
curve_radius = radius;


arch_length = radius * angle * PI / 180.0;
pillar_thickness = 18;
hole_radius = (arch_length - pillar_thickness) / 2;

top_thickness = 15;

pillar_height = bridge_height - top_thickness - hole_radius;


/* [Track] */
track_width = 26;


/* [Brick parameters] */
brick_length = 5.6;
brick_width = 4;
brick_height = 2.25; // [2:0.05:4]

brick_randomness = 0.2;
brick_gap = 0.8;
brick_chamfer = 0.2;
brick_depth = 0.6;

$fn = 90;

function bridge_bend(c) = vnf_bend(skew(c, szx=grade/100.0), r=radius, axis="Z");
module bridge_poly(c) {
    vnf_polyhedron(bridge_bend(c));
}

module bridge_hull() {
    c = back(radius-track_width/2, cube([arch_length, track_width, bridge_height]));
    bridge_poly(c);
}

module bridge_hole_top(r=hole_radius) {
    c = up(pillar_height, right(arch_length/2, back(radius+track_width/2+1, xrot(90, cylinder(h=track_width+4, r=r)))));
    bridge_poly(c);
}

module bridge_hole_lower() {
    c = right(pillar_thickness/2, back(radius-track_width/2-1, cube([2*hole_radius, track_width+2, pillar_height])));
    bridge_poly(c);
}

module pillar_side_bricks(y) {
        for (i = [0:10]) {
            bridge_translate([brick_length/2, y, i*5]) {
                brick();
            }
            bridge_translate([brick_length+brick_width/2, y, i*5]) {
                brick(brick_width);
            }
            bridge_translate([brick_length/4, y, i*5 + 2.5]) {
                brick(brick_length/2);
            }
            bridge_translate([5*brick_length/4, y, i*5 + 2.5]) {
                brick();
            }
        }
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
    up(brick_height/2) {
        pillar_side_bricks(track_width/2-1);
        pillar_side_bricks(-track_width/2+1);
    }  
    }
    
    // Top wall
    color("green")
    difference() {
        up(pillar_height) {
            brick_wall(arch_length, bridge_height-pillar_height, out=track_width/2-1);
            brick_wall(arch_length, bridge_height-pillar_height, out=-track_width/2+1);
       }
       bridge_hole_top(r=hole_radius + brick_length);
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
                
        translate(tunnel_pos) zrot(point_angle) yrot(do_rotate ? -turn_sign * grade_angle : 0) scale(scale_factor) children();
    }
}

module bridge_translate_direct(pos) {
    bridge_translate(pos, do_rotate=false, do_scale=false) children();
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

          
module brick_wall(length, height, out = 0, symm = false, holes=[], invert_odd=false, open=false, radius=0) {
  points = (symm) ? wall_points_symm(length, height, invert_odd) : open ? wall_points_open(length, height, invert_odd) : wall_points(length, height, invert_odd);
  for(p = points) {
    pos = [p[0], p[1], p[2]];
    bridge_translate([pos[0], pos[1]+out, pos[2]]) {
      angle_cut = (len(holes) > 0) ? brick_cut_angle(pos, holes[0]) : [true, 0, 0];
      if (angle_cut[0]) {
        brick(length = p[3], width = p[4], height = p[5], cut_angle=angle_cut[1]);
    }}
  }
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

