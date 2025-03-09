// include <BOSL2/std.scad>;
include <brick.scad>
;

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
  let (lw = (l - brick_width) / 2)
    is_odd ? [
      [brick_width / 2, lw, e + h / 2, brick_width, l, h], 
      if (c > 0)
        for (i = [1:c])
          [brick_width - l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
    ] : [
      if (c > 0)
        for (i = [1:c])
          [-l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
      [(c) * l + brick_width / 2, lw, e + h / 2, brick_width, l, h], 
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

function wall_points(length, height) =
  let (whole_brick_length = length - brick_width)
    let (whole_brick_count = round(whole_brick_length / brick_length))
      let (i_brick_length = whole_brick_length / whole_brick_count)
        let (row_brick_count = whole_brick_count)
          let (row_count = round(height / brick_height))
            let (i_brick_height = height / row_count)
              flatten([
                for (r = [0:row_count - 1])
                  row_points(row_brick_count, i_brick_length, r * i_brick_height, i_brick_height, r % 2 == 1), 
              ]);

function wall_points_symm(length, height) =
  let (row_brick_count = round(length / brick_length))
    let (i_brick_length = length / row_brick_count)
      let (row_count = round(height / brick_height))
        let (i_brick_height = height / row_count)
          flatten([
            for (r = [0:row_count - 1])
              row_points_symm(row_brick_count, i_brick_length, r * i_brick_height, i_brick_height, r % 2 == 1), 
          ]);

function sqr(x) = x * x;

function point_distance(p1, p2) = sqrt(sqr(p1[0] - p2[0]) + sqr(p1[1] - p2[1]) + sqr(p1[2] - p2[2]));
            
function point_angle(p1, p2) = 180 - atan2(p2[2]-p1[2], p2[0]-p1[0]);

function brick_cut_angle(pos, hole) = 
  let (d = point_distance(pos, hole[0]))
    (d > hole[1]) ? [true, 0, 0] :
      ((d > hole[1] - brick_length) ? [true, point_angle(pos, hole[0]), hole[1] - d] :
        [false, 0, 0]);

module brick_wall(length, height, symm = false, holes=[]) {
  points = (symm) ? wall_points_symm(length, height) : wall_points(length, height);
  for(p = points) {
    pos = [p[0], p[1], p[2]];
    translate(pos) {
      angle_cut = (len(holes) > 0) ? brick_cut_angle(pos, holes[0]) : [true, 0, 0];
      if (angle_cut[0]) {
        brick(length = p[3], width = p[4], height = p[5], cut_angle=angle_cut[1]);
    }}
  }
}

module tunnel_entrance(radius, side_width, side_height) {
    width = 2*radius + 2*side_width;
    
    left(radius) {
        mirror([1, 0, 0])
            brick_wall(side_width, side_height);
    }
    right(radius) {
        brick_wall(side_width, side_height);
    }
    
    up(side_height) {
        brick_arch(radius);
        
        left(width/2) {
            brick_wall(width, 30, symm=true, holes=[[[width/2, 0, 0], radius+2*brick_length]]);
        }
    }
}

tunnel_entrance(18, 14, 24);
