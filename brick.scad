include <BOSL2/std.scad>;

brick_length = 7;
brick_width = 5;
brick_height = 3;

brick_randomness = 0.2;
gap = 0.8;

module brick(length=brick_length, width=brick_width, height=brick_height) {
    r = rands(-0.2, 0.2, 6);
    rrot = rands(-2, 2, 3);
    rotate(rrot)
    cuboid([length-gap+r[0], width-gap+r[1], height-gap+r[2]], chamfer=0.2);
}
