include <BOSL2/std.scad>
;

brick_length = 7;
brick_width = 5;
brick_height = 3;

brick_randomness = 0.2;
brick_gap = 0.8;
brick_chamfer = 0.2;

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

module brick_arch(inner_radius, alternating = true) {
  radius = inner_radius + brick_length/2;
  arch_length = radius * PI;
  // The number of bricks has to always be 4k+1, so that
  // both edge bricks and the center (top) one are always
  // horizontal.
  brick_count_p = 4 * floor(arch_length / brick_height / 4) + 1;
  brick_height = arch_length / brick_count_p;
  brick_count = brick_count_p - 1;
  angle = 180 / brick_count_p;

  hl = brick_length / 2;
  ql = brick_length / 4;

  for(i = [0:brick_count]) {
    yrot(-(i + 0.5) * angle)
      right(radius) {
        if (!alternating || i % 2 == 0) {
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

/*
brick_arch(20);

brick_arch(40);

up(4)
    brick(cut_angle=30);

up(8)
    brick(cut_angle=60);
*/

/*
zdistribute(3) {
    brick(cut_angle=-60);
    brick(cut_angle=60);
    brick(cut_angle=0);
    brick(cut_angle=60);
}
*/

// brick_arch(10);
