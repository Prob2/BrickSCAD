include <BOSL2/std.scad>

/* [Bridge] */
bridge_height = 100;

grade = -4;
radius = 150;
angle = 45;
straight = false;

grade_angle = atan(grade / 100);
turn_sign = 1;
curve_radius = radius;


arch_length = radius * angle * PI / 180.0;
pillar_thickness = 19.5;
hole_radius = (arch_length - pillar_thickness) / 2;
half_pillar_thickness = pillar_thickness / 2;

top_thickness = 10.5;

pillar_height = bridge_height - top_thickness - hole_radius;


/* [Track] */
track_width = 28;


/* [Brick parameters] */
brick_length = 5.6;
brick_width = 4;
brick_height = 2.25; // [2:0.05:4]

brick_randomness = 0.2;
brick_gap = 0.8;
brick_chamfer = 0.2;
brick_depth = 0.8;

odd_row_offset = brick_length / 2;
pillar_offset = 2;

$fn = 90;

function bridge_bend(c, bent = true) = 
    let (s = skew(c, szx=grade/100.0))
    bent ? vnf_bend(s, r=radius, axis="Z") : s;
    
module bridge_poly(c, bent = true) {
    vnf_polyhedron(bridge_bend(c, bent));
}

module bridge_hull(bent = true) {
    c = back(radius-track_width/2, cube([arch_length, track_width, bridge_height]));
    bridge_poly(c, bent);
}

module bridge_hole_top(r=hole_radius, bent=true) {
    c = up(pillar_height, right(arch_length/2, back(radius+track_width/2+1, xrot(90, cylinder(h=track_width+4, r=r)))));
    bridge_poly(c, bent);
}


module bridge_hole_cut(r=hole_radius, y=0, t=1, bent=true) {
    c = up(pillar_height, right(arch_length/2, back(radius+y, xrot(y < 0 ? 90 : -90, cylinder(h=t, r1=r, r2=r+t)))));
    bridge_poly(c, bent);
}

module bridge_hole_lower(bent=true) {
    c = down(1, right(pillar_thickness/2, back(radius-track_width/2-1, cube([2*hole_radius, track_width+2, pillar_height+1]))));
    bridge_poly(c, bent);
}

module track_cutout(bent=true) {
    width = 25.5;
    floor_height = 1.3;
    height = 7.2;
    gauge = 9.8;
    ballast_width = 18;
    ballast_height = 5.1;
    attachment_width = 1.25;
    attachment_height = 1;
    clearance = 0.15;

    f = left(1, back(radius, cube([arch_length+2, width, floor_height], anchor=BOTTOM+LEFT)));
    b = left(1, back(radius, cube([arch_length+2, ballast_width, ballast_height], anchor=BOTTOM+LEFT)));
    
    skew_s = (width - ballast_width) / ballast_height / 2;
    skew_x = (width - ballast_width) / 2;
    
    up(bridge_height)
    union() {
        bridge_poly(down(floor_height+ballast_height-0.1, f), bent);
        bridge_poly(down(ballast_height-0.1, back(-skew_x, skew(syz=skew_s, b))), bent);
        bridge_poly(down(ballast_height-0.1, back(skew_x, skew(syz=-skew_s, b))), bent);
    }
}

pillar_row_count = floor(pillar_height / brick_height / 2) - 1;
pillar_row_offset = pillar_height - (pillar_row_count+1) * 2 * brick_height;

module pillar_side_bricks(y, f=1, side=1, bent=true) {
        odd_h = brick_height/2 * (1-f*side);
        even_h = brick_height/2 * (1+f*side);
        scale_f = 1 - y/radius;
        
        up(pillar_row_offset) {
        
        for (i = [0:pillar_row_count]) {
            bridge_translate([f*(half_pillar_thickness + brick_gap - brick_length/2 - brick_width), y, i*brick_height*2 + odd_h], bent=bent) {
                brick(length=brick_length * scale_f);
            }
            bridge_translate([f*(half_pillar_thickness + brick_gap - brick_width/2), y - side * (brick_length/2 - brick_width/2), i*brick_height*2 + odd_h], bent=bent) {
                zrot(90) brick(width=brick_width * scale_f);
            }
            bridge_translate([f*(half_pillar_thickness + brick_gap - brick_length - brick_length/2), y, i*brick_height*2 + even_h], bent=bent) {
                brick(length=brick_length * scale_f);
            }
            bridge_translate([f*(half_pillar_thickness + brick_gap - brick_length/2), y, i*brick_height*2 + even_h], bent=bent) {
                brick(length=brick_length * scale_f);
            }
        }
        }
}


module pillar_inside_bricks(x, f=1, bent=true) {
        l = track_width + 2 * brick_depth - brick_length - brick_width;
        n = round(l / brick_length);
        i_brick_length = l / n;
        
        start = -track_width/2 - brick_depth; 
        
        odd_h = brick_height/2 * (1-f);
        even_h = brick_height/2 * (1+f);

        up(pillar_row_offset) {

        for (i = [0:pillar_row_count]) {
            for (j = [0:n-1]) {
                bridge_translate([x, start + brick_width + (j+0.5) * i_brick_length, i*brick_height*2 + odd_h], bent=bent) {
                    zrot(90) brick(length=i_brick_length);
                }
                bridge_translate([x, start + brick_length + (j+0.5) * i_brick_length, i*brick_height*2 + even_h], bent=bent) {
                    zrot(90) brick(length=i_brick_length);
                }
            }
        }
        }
}

module bridge(bent=true) {
    // Main body
    difference() {
        bridge_hull(bent=bent);
        bridge_hole_top(bent=bent);
        bridge_hole_lower(bent=bent);
    }
    
    d = brick_width/2 - brick_depth;
    t = track_width/2 - d;
    
    // Pillar side bricks
    color("red") {
    up(0) {
        pillar_side_bricks(t, 1, 1, bent=bent);
        pillar_side_bricks(-t, 1, -1, bent=bent);
        
        up(grade/100.0*arch_length) {
            if (bent)
            zrot(-angle) {
                pillar_side_bricks(t, -1, 1, bent=bent);
                pillar_side_bricks(-t, -1, -1, bent=bent);
            }
            else
            right(arch_length) {
                pillar_side_bricks(t, -1, 1, bent=bent);
                pillar_side_bricks(-t, -1, -1, bent=bent);
            }
        }
    }
    }
    
    // Pillar inside bricks
    color("blue") {
        up(0) {
            pillar_inside_bricks(half_pillar_thickness-d, 1, bent=bent);
            pillar_inside_bricks(arch_length-half_pillar_thickness+d, -1, bent=bent);
        }
    }
    
    holes = [arch_length/2, 0, hole_radius];
    
    twcr = hole_radius + brick_length - brick_depth + brick_gap/2;
    
    // Top wall
    color("green")
    difference() {
        up(pillar_height-brick_height/2) {
            brick_wall(arch_length, bridge_height-pillar_height, out=t, holes=holes, bent=bent);
            brick_wall(arch_length, bridge_height-pillar_height, out=-t, holes=holes, bent=bent);
       }
       bridge_hole_top(r=twcr, bent=bent);
       bridge_hole_cut(r=twcr, y=track_width/2, bent=bent);
       bridge_hole_cut(r=twcr, y=-track_width/2, bent=bent);
   }
   
   // Side arch
   color("cyan") {
     up(pillar_height) {
        brick_arch(inner_radius=hole_radius + brick_length/2 - brick_depth, y=t, odd=false, bent=bent);
        brick_arch(inner_radius=hole_radius + brick_length/2 - brick_depth, y=-t, odd=true, bent=bent);
     }
   }
}

module bridges(n=1, s=1) {
    union() {
        for (i=[0:n-1]) {
            up(i*grade/100.0*arch_length)
                zrot(-i*angle)
                    difference() {
                        bridge(bent=true);
                        track_cutout(bent=true);
                    }
        }
        for (i=[1:s])
        up(-i*grade/100.0*arch_length)
        left(i*arch_length)
            difference() {
                bridge(bent=false);
                track_cutout(bent=false);
            }

    }
}

intersection() {
    bridges(4, 2);
    /*
    zrot(90 - angle/2 - 2*angle)
        down(bridge_height)
        pie_slice(r=2*radius, h=3*bridge_height, ang=2*angle);
    */
}

module bridge_translate(pos, do_rotate=true, do_scale=true, bent=true) {
    if (!bent) {
        translate([pos[0], -pos[1] + curve_radius, pos[2] + grade/100*pos[0]]) children();
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

module bridge_translate_direct(pos, bent=true) {
    bridge_translate(pos, do_rotate=false, do_scale=false, bent=bent) children();
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
      
function row_points_offset(c, l, e, h, is_odd) = 
  let (lw = (brick_length - brick_width) / 2)
    let (first_offset = is_odd ? odd_row_offset : 0)
      [for (i = [1:c]) [-l/2 + i * l + first_offset, 0, e+h/2, l, brick_width, h]];

function wall_points_offset(length, height, invert_odd) =
  let (whole_brick_length = length)
    let (whole_brick_count = round(whole_brick_length / brick_length))
      let (i_brick_length = whole_brick_length / whole_brick_count)
        let (row_brick_count = whole_brick_count)
          let (row_count = round(height / brick_height))
            let (i_brick_height = height / row_count)
              flatten([
                for (r = [0:row_count - 1])
                  row_points_offset(row_brick_count, i_brick_length, r * brick_height, brick_height, (r % 2 == 0) == invert_odd), 
              ]);

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

function is_in_hole(pos, hole) = 
    len(hole) == 0 ? false :
    let (x = pos[0] - hole[0])
    let (y = pos[2] - hole[1])
    sqrt(x*x + y*y) < hole[2];
          
module brick_wall(length, height, out = 0, symm = false, holes=[], invert_odd=false, open=false, bent=true) {
  points = (symm) ? wall_points_symm(length, height, invert_odd) : open ? wall_points_open(length, height, invert_odd) : wall_points_offset(length, height, invert_odd);
  for(p = points) {
    pos = [p[0], p[1], p[2]];
    if (!is_in_hole(pos, holes)) {
      bridge_translate([pos[0], pos[1]+out, pos[2]], bent=bent) {
        brick(length = p[3] * (1 - out/radius), width = p[4], height = p[5]);
      }
    }
  }
}

function adjust_to_ab(n, a, b) = round((n - b) / a) * a + b;

arch_rows_length = hole_radius * PI;
arch_row_count = adjust_to_ab(arch_rows_length / brick_height, 2, 1);
arch_row_angle = 180.0 / arch_row_count;


module brick_arch(inner_radius, y, alternating = true, odd=false, bent=true) {

  hl = brick_length / 2;
  ql = brick_length / 4;
  
    l = track_width + 2 * brick_depth - brick_length - brick_width;
    n = round(l / brick_length);
    i_brick_length = l / n;
  
  for (i = [0:arch_row_count]) {
    angle = arch_row_angle * i;
    x = arch_length/2 - inner_radius * cos(angle);
    z = inner_radius * sin(angle);
    
    bridge_translate([x, y, z], bent=bent) {
      yrot(angle) {
        if (!alternating || (i % 2 == 0) == odd) {
          brick(radius = radius, length = brick_length, height = brick_height);
        } else {
          back((brick_length / 2 - brick_width / 2) * sign(y)) {
            left(ql)
              brick(radius = radius - ql, length = hl, height = brick_height * (radius - ql) / radius, width = brick_length);
            right(ql)
              brick(radius = radius + ql, length = hl, height = brick_height * (radius + ql) / radius, width = brick_length);
          }
        }
      }
    }

    if (alternating && (i % 2 == 1) == odd) {
        for (j = [0:n-1]) {
            bridge_translate([x, y - (brick_depth + brick_length + j*i_brick_length)*sign(y), z], bent=bent) {
            yrot(angle)
                right(ql)
                    brick(radius = radius + ql, length = hl, height = brick_height * (radius + ql) / radius, width = i_brick_length);
            }
        }
    }
  }
}
