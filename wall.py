from dataclasses import dataclass
import math
import itertools

import cadquery as cq

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

@dataclass
class RowParameters:
    length: float
    height: float
    brick: BrickParameters
    num_bricks: int
    odd: bool
    symmetric: bool
    half_brick_length: float
    
    def brick_widths(self) -> list[float]:
        if self.symmetric:
            if self.odd:
                h = self.half_brick_length
                return [h] + [self.brick.length for _ in range(self.num_bricks-1)] + [h]
            else:
                return [self.brick.length for _ in range(self.num_bricks)]
        else:
            h = self.half_brick_length
            if self.odd:
                return [self.brick.length for _ in range(self.num_bricks-1)] + [h]
            else:
                return [h] + [self.brick.length for _ in range(self.num_bricks-1)]
    
    def brick_data(self, y, z, loc) -> list[BrickData]:
        w = self.brick_widths()
        xs = [0] + list(itertools.accumulate(w))[:-1]
        xm = [(x, w) for x, w in zip(xs, w)]
        return [BrickData(
            p=BrickParameters(
                length=w,
                width=self.brick.width if w == self.brick.length else self.brick.length,
                height=self.height,
                gap=self.brick.gap,
            ),
            pos=loc * cq.Location(x, y, z),
            rot=cq.Vector(0, 0, 0),
        )
        for x, w in xm]

def flatten(xss):
    return [x for xs in xss for x in xs]

@dataclass
class WallParameters:
    length: float
    height: float
    symmetric: bool = False
    
    def brick_data(self, base: BrickParameters, loc: cq.Location, reverse_rows=False) -> list[BrickData]:
        rows = self.rows(base, reverse_rows)
        return flatten([r.brick_data(0, i * base.height, loc) for i, r in enumerate(rows)])
    
    def rows(self, base: BrickParameters, reverse_rows=False) -> list[RowParameters]:
        num_rows = round(self.height / base.height)
        row_height = self.height / num_rows
        
        effective_length = self.length if self.symmetric else self.length + base.length - base.width
        num_bricks = round(effective_length / base.length)
        print(num_bricks)
        brick_length = effective_length / num_bricks
        print(brick_length)
        print(num_bricks * brick_length)
        half_length = brick_length / 2 if self.symmetric else base.width * brick_length / base.length
        return [
            RowParameters(
                length=self.length,
                height=row_height,
                symmetric=self.symmetric,
                num_bricks=num_bricks,
                half_brick_length=half_length,
                odd=((r%2 == 1) != reverse_rows),
                brick=BrickParameters(
                    length=brick_length,
                    width=base.width,
                    height=row_height,
                    gap=base.gap,
                )
            )
            for r in range(num_rows)
        ]
    
def tunnelProfile(radius, side_height):
    return cq.Workplane("front").moveTo(-radius, 0).lineTo(-radius, side_height).threePointArc((0,radius + side_height), (radius, side_height)).lineTo(radius,0).close()

def straightTunnelProfile():
    return tunnelProfile(radius=14, side_height=22)

def curvedTunnelProfile():
    return tunnelProfile(radius=18, side_height=20)

def make_brick(d: BrickData):
    b = cq.Solid.makeBox(d.p.length - d.p.gap, d.p.width - d.p.gap, d.p.height - d.p.gap)
    b = b.chamfer(0.3, None, b.edges())
    # rpos = cq.Location(r(0, s=0.2), r(0, s=0.2),r(0, s=0.2),)
    
    return b.moved(d.pos)

if __name__ == "__cq_main__":
    # result = cq.Workplane("XY" ).box(3, 3, 0.5).edges("|Z").fillet(0.125)
    # result = curvedTunnelProfile().extrude(100).faces("|Z or -Y").shell(1)
    
    l_wall = WallParameters(length=10, height=24, symmetric=False)
    brick = BrickParameters(length=6, width=4, height=3, gap=0.8)
    l_points = l_wall.brick_data(brick, cq.Location(0, 0, 0))

    t_wall = WallParameters(length=48, height=20, symmetric=True)
    brick = BrickParameters(length=6, width=4, height=3, gap=0.8)
    t_points = t_wall.brick_data(brick, cq.Location(0, 0, l_wall.height), reverse_rows=True)
    
    r_points = l_wall.brick_data(brick, cq.Location(38, 0, 0), reverse_rows=True)

    result = (
        cq
            .Workplane("XZ")
            .newObject(l_points + t_points + r_points)
            .each(make_brick)
            .workplane(0.3)
            .moveTo(24, 22)
            .rect(49, 45)
            .extrude(1)
    )
    show_object(result)
