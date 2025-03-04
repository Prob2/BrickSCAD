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
class RowParameters:
    length: float
    height: float
    brick_length: float
    num_bricks: int
    odd: bool
    symmetric: bool
    half_brick_length: float
    
    def brick_widths(self) -> list[float]:
        if self.symmetric:
            if self.odd:
                h = self.half_brick_length
                return [h] + [self.brick_length for _ in range(self.num_bricks-1)] + [h]
            else:
                return [self.brick_length for _ in range(self.num_bricks)]
        else:
            h = self.half_brick_length
            if self.odd:
                return [self.brick_length for _ in range(self.num_bricks-1)] + [h]
            else:
                return [h] + [self.brick_length for _ in range(self.num_bricks-1)]
    
    def brick_locations(self) -> list[cq.Location]:
        w = self.brick_widths()
        xs = [0] + list(itertools.accumulate(w))[:-1]
        xm = [x+w/2 for x, w in zip(xs, w)]
        return [cq.Location(x, 0, 0) for x in xm]

@dataclass
class WallParameters:
    length: float
    height: float
    symmetric: bool
    
    def brick_locations(self) -> list[cq.Location]:
        return []
    
    def rows(self, base: BrickParameters) -> list[RowParameters]:
        num_rows = math.round(self.height / base.height)
        row_height = self.height / base.height
        return [
            BrickParameters()
            for r in range(num_rows)
        ]

if __name__ == "__cq_main__":
    result = cq.Workplane("XY" ).box(3, 3, 0.5).edges("|Z").fillet(0.125)
    show_object(result)
