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

module brick(length = brick_length, width = brick_width, height = brick_height, rf = brick_randomness, radius = 0, gap = brick_gap, chamfer = brick_chamfer) {

  r = rands(-rf, rf, 7);
  rrot = rands(-10 * rf, 10 * rf, 3);

  stretch = (radius != 0) ? (height / radius / 2) : 0;

  size = [length - gap + r[0], width - gap + r[1], height - gap + r[2] - stretch * length];

  rotate(rrot) {
    union() {
      if (2 * stretch * length > height)
        brick_base(size, chamfer);

      if (radius != 0) {
        union() {
          up(stretch / 2 * length)
            skew(szx = stretch)
              brick_base(size, chamfer);
          down(stretch / 2 * length)
            skew(szx = -stretch)
              brick_base(size, chamfer);
        }
      }
    }
  }
}

brick();

module brick_arch(radius, alternating = true) {
  arch_length = radius * PI;
  // The number of bricks has to always be 4k+1, so that
  // both edge bricks and the center (top) one are always
  // horizontal.
  brick_count_p = 4 * round(arch_length / brick_height / 4) + 1;
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

brick_arch(20);

brick_arch(40);
