include <BOSL2/std.scad>

/* [Bridge] */
bridge_height = 80;

grade = -4;
radius = 150;
angle = 45;

arch_length = radius * angle * PI / 180.0;
pillar_thickness = 20;
hole_radius = (arch_length - pillar_thickness) / 2;


/* [Track] */
track_width = 26;

$fn = 90;

module bridge_hull() {
    c = back(radius-track_width/2, cube([arch_length, track_width, bridge_height]));
    s = skew(c, szx=grade / 100.0);
    b = vnf_bend(s, r=radius, axis="Z");
    vnf_polyhedron(b);
}

module bridge_hole() {
    c = back(radius+track_width/2+1, xrot(90, cylinder(h=track_width+2, r=50)));
    s = skew(c, szx=grade / 100.0);
    b = vnf_bend(s, r=radius, axis="Z");
    r = zrot(-angle/2, b);
    vnf_polyhedron(r);    
}

module bridge() {
difference() {
    bridge_hull();
    bridge_hole();
}
}

module bridges(n=4) {
    union() {
    for (i=[0:n-1]) {
        up(i*grade/100.0*arch_length)
            zrot(-i*angle)
                bridge();
    }
    }
}

bridges();