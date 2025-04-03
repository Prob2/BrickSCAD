from openscad import *

bosl = osinclude("BOSL2/std.scad")

def split_triangles(points, faces, resolution):
    print("points:", points)
    print("faces:", faces)
    return (points, faces)

if __name__ == "__main__":
    c = cube([10, 40, 10])
    (points, faces) = c.mesh()
    resolution = 10
    (split_points, split_faces) = split_triangles(points, faces, resolution)
    v = polyhedron(points, faces);
    v.show()
