import cadquery as cq

def make_helix(radius, angle, grade, lefthand):
    length = radius * angle * 2 * math.PI / 360
    pitch = radius * 2 * PI * grade
    height = length * grade
    return cq.Wire.makeHelix(pitch=pitch, height=height, radius=radius, lefthand=lefthand)

def station_tunnel_curve():
    wires = [
        make_helix(150, 45, 0.04, False)
    ]
    wire = cq.Wire.makeHelix(pitch=p, height=h, radius=r)
    shape = cq.Wire.combine([wire])
    helix = cq.Workplane(obj=shape)
    