import cadquery as cq
# from cq_server.ui import ui, show_object 

from dataclasses import dataclass
from typing import Optional

@dataclass
class BrickParameters:
    length: float
    width: float
    height: float
    gap: float

@dataclass
class BrickData:
    p: BrickParameters
    pos: cq.Location
    rot: cq.Vector
    cut: Optional[tuple[cq.Location, int]] = None

def make_brick(d: BrickData):
    s = cq.Sketch().rect(d.p.length - d.p.gap, d.p.height - d.p.gap)
    if d.cut is not None:
        (center, radius) = d.cut
        s.moveTo(center)
        s = s.circle(radius, mode="s")

    b = cq.Workplane("front").placeSketch(s).extrude(d.p.width - d.p.gap)

    # b = cq.Solid.makeBox(d.p.length - d.p.gap, d.p.width - d.p.gap, d.p.height - d.p.gap).moved(d.pos)

    # b = b.chamfer(0.3)
    # rpos = cq.Location(r(0, s=0.2), r(0, s=0.2),r(0, s=0.2),)
    
    return b.val()

def bricks(self, data: list[BrickData]):
    self.newObject(data).each(make_brick)

cq.Workplane.bricks = bricks

def example_base():
    obj = cq.Workplane().box(6, 3, 1)
    show_object(obj)

def example():
    pos = cq.Location(cq.Vector(0.0, 0.0, 0.0))
    data = [
        BrickData(
            p = BrickParameters(5, 3, 1, 0.8),
            pos = cq.Location(cq.Vector(0.0, 0.0, 0.0)),
            rot = cq.Vector(0, 0, 0),
        ),
        BrickData(
            p = BrickParameters(5, 3, 1, 0.8),
            pos = cq.Location(cq.Vector(7.0, 0.0, 0.0)),
            rot = cq.Vector(0, 0, 0),
        ),
    ]
    obj = cq.Workplane().bricks(data)
    show_object(obj)

example()
