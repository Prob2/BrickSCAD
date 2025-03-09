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
      if (c >= 2)
        for (i = [1:c - 1])
          [brick_width - l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
    ] : [
      if (c >= 2)
        for (i = [1:c - 1])
          [-l / 2 + i * l, 0, e + h / 2, l, brick_width, h], 
      [(c - 1) * l + brick_width / 2, lw, e + h / 2, brick_width, l, h], 
    ];

function row_points_symm(c, l, e, h, is_odd) =
  let (lw = (l - brick_width) / 2)
    is_odd ? [
      [l / 4, lw, e + h / 2, l / 2, l, h], 
      if (c >= 2)
        for (i = [1:c - 2])
          [i * l, 0, e + h / 2, l, brick_width, h], 
      [(c - 1) * l - l / 4, lw, e + h / 2, l / 2, l, h], 
    ] : [
      if (c >= 2)
        for (i = [1:c - 1])
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

module brick_wall(length, height) {
  for(p = wall_points(length, height)) {
    translate([p[0], p[1], p[2]]) {
      brick(length = p[3], width = p[4], height = p[5]);
    }
  }
}

module brick_wall(length, height, symm = false) {
  points = (symm) ? wall_points_symm(length, height) : wall_points(length, height);
  for(p = points) {
    translate([p[0], p[1], p[2]]) {
      brick(length = p[3], width = p[4], height = p[5]);
    }
  }
}

xdistribute(30) {
  brick_wall(21, 40);
  brick_wall(21, 40, symm = true);
}
