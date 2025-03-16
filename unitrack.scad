include <BOSL2/std.scad>

width = 25.5;
floor_height = 1;
height = 7.2;
gauge = 9.8;
ballast_width = 18;
ballast_height = 5.1;
attachment_width = 1.25;
attachment_height = 1;
clearance = 0.15;

module mirrored() {
    children();
    mirror([1, 0, 0]) children();
}

module unitrack(length, clearance=clearance) {
    mirrored()
    linear_extrude(length) {
        offset(clearance) {
            polygon([
                [0, 0],
                [width/2, 0],
                [width/2, floor_height],
                [ballast_width/2, ballast_height],
                [gauge/2+attachment_width, ballast_height],
                [gauge/2+attachment_width, ballast_height+attachment_height],
                [gauge/2, ballast_height+attachment_height],
                [gauge/2, height],
                [0, height],
            ]);
        }
    }
}

// unitrack(128);

module crossing(road_width) {

    difference() {
        translate([-width/2-2, -2, 1]) cube([width+4, height+2, 40]);
        // unitrack(42);
    }

    translate([width/2, -2, 1]) {
        intersection() {
            cube([20, height+2, 40]);
            translate([0, -50+height+2, 0])
                cylinder(h=40, r=50, $fn=360);
        }
    }

    translate([-width/2-20, -2, 1]) {
        intersection() {
            cube([20, height+2, 40]);
            translate([20, -50+height+2, 0])
                cylinder(h=40, r=50, $fn=360);
        }
    }

    translate([-width/2-40+0.4, -2, 1]) {
        difference() {
            cube([20, height+2, 40]);
            translate([0, 51, -1])
                cylinder(h=42, r=50, $fn=360);
        }
    }
}

skew_angle = 22.5;
skew_amount = tan(skew_angle);
road_width = 40 * sin(skew_angle);

difference() {
    skew(sxz=skew_amount) crossing(road_width);
    rotate([0, skew_angle, 0])
        translate([-3, 0, -20]) {
            unitrack(100);
        }
}

translate([-width/2-40, -2, 1]) {
    cube([20, 1, 40]);
}

guide_radius = 10;
guide_radius_2 = 11.1;

module guide() {
    rotate([90, 0, 0]) {
        intersection() {
            translate([guide_radius + 3.6, 0, -1]) cylinder(h=1, r=guide_radius + 3.6, $fn=90);
            translate([-guide_radius + 3.6, 0, -1]) cylinder(h=1, r=guide_radius + 3.6, $fn=90);
        }
        translate([-0.4, 1, 0])
        intersection() {
            translate([guide_radius_2 + 4, 0, -2]) cylinder(h=1, r=guide_radius_2 + 4, $fn=90);
            translate([-guide_radius_2 + 4, 0, -2]) cylinder(h=1, r=guide_radius_2 + 4, $fn=90);
        }
    }
}

module middle() {
    translate([-3.6, 30, 0]) {
        skew(sxz=skew_amount) {
            cube([7.2, 1, 40]);
            translate([-0.4, 1, 0]) {
                cube([8, 1, 40]);
            }
            guide();
            translate([0, 0, 40]) {
                mirror([0, 0, 1]) guide();
            }
        }
    }
}

middle();