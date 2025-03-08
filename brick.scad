include <BOSL2/std.scad>;

brick_length = 7;
brick_width = 5;
brick_height = 3;

brick_randomness = 0.2;
gap = 0.8;

module brick_base(size) {
    cuboid(size, chamfer=0.2);
}

module brick(length=brick_length, width=brick_width, height=brick_height, rf=0.2, radius=0) {
    
    r = rands(-rf, rf, 7);
    rrot = rands(-10*rf, 10*rf, 3);
    
    stretch = (radius != 0) ? (1/radius) : 0;
    
    size = [length-gap+r[0], width-gap+r[1], height-gap+r[2]-stretch*length];
    
    rotate(rrot) {
        union() {
            brick_base(size);

        if (radius != 0) {
            union() {
                up(stretch/2 * length)
                skew(szx=stretch)
                brick_base(size);
                down(stretch/2 * length)
                skew(szx=-stretch)
                brick_base(size);
            }
        }
    }
}
}

brick();

radius = 20;

for (i=[0:20]) {
    yrot(-(i+0.5)*90/10.5) right(radius) {
        if (i%2 == 0) {
            brick(radius=radius, length=(i%2==0) ? 6 : 3);
        } else {
            left(1.5)
                brick(radius=radius, length=3, height=brick_height * (radius-1.5) / radius);
            right(1.5)
                brick(radius=10, length=3, height=brick_height * (radius+1.5) / radius);
        }
    }
}
