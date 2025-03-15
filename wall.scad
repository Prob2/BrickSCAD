// include <BOSL2/std.scad>;
include <brick.scad>;

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
                  row_points(row_brick_count, i_brick_length, r * i_brick_height, i_brick_height, (r % 2 == 0) == invert_odd), 
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
                  row_points_open(row_brick_count, i_brick_length, r * i_brick_height, i_brick_height, (r % 2 == 0) == invert_odd), 
              ]);

function wall_points_symm(length, height, invert_odd) =
  let (row_brick_count = round(length / brick_length))
    let (i_brick_length = length / row_brick_count)
      let (row_count = round(height / brick_height))
        let (i_brick_height = height / row_count)
          flatten([
            for (r = [0:row_count - 1])
              row_points_symm(row_brick_count, i_brick_length, r * i_brick_height, i_brick_height, (r % 2 == 0) == invert_odd), 
          ]);

function sqr(x) = x * x;

function point_distance(p1, p2) = sqrt(sqr(p1[0] - p2[0]) + sqr(p1[1] - p2[1]) + sqr(p1[2] - p2[2]));
            
function point_angle(p1, p2) = 180 - atan2(p2[2]-p1[2], p2[0]-p1[0]);

function brick_cut_angle(pos, hole) = 
  let (d = point_distance(pos, hole[0]))
    (d > hole[1]) ? [true, 0, 0] :
      ((d > hole[1] - brick_length) ? [true, point_angle(pos, hole[0]), hole[1] - d] :
        [false, 0, 0]);

module translate_with_radius(pos, radius=0) {
    if (radius == 0) {
        translate(pos) children();
    } else {
        angle = 180 / PI * pos[2] / radius;
        z_scale_factor = (radius - brick_height/2) / radius;
        
        translate([0, -radius, 0])
        xrot(angle)
        translate([pos[0], pos[1]+radius, 0]) scale([1, 1, z_scale_factor]) children();
    }
}
        
module brick_wall(length, height, symm = false, holes=[], invert_odd=false, open=false, radius=0) {
  points = (symm) ? wall_points_symm(length, height, invert_odd) : open ? wall_points_open(length, height, invert_odd) : wall_points(length, height, invert_odd);
  for(p = points) {
    pos = [p[0], p[1], p[2]];
    translate_with_radius(pos, radius) {
      angle_cut = (len(holes) > 0) ? brick_cut_angle(pos, holes[0]) : [true, 0, 0];
      if (angle_cut[0]) {
        brick(length = p[3], width = p[4], height = p[5], cut_angle=angle_cut[1]);
    }}
  }
}

module brick_wall_corner(l1, l2, height) {
    brick_wall(l1, height);
    translate([l1-brick_width/2, brick_length-brick_width/2, 0]) {
        zrot(90) {
            brick_wall(l2, height, open=true);
        }
    }
}

// brick_wall_corner(14, 50, 24);

brick_wall(100, 20 * PI, radius=20, open=true);