from dataclasses import dataclass

import cadquery as cq

@dataclass
class BrickParameters:
    length: float
    width: float
    height: float
    gap: float

@dataclass
class WallParameters:
    length: float
    height: float
    symmetric: bool
    
    def brick_locations(self) -> list[cq.Location]:
        return []

@dataclass
class RowParameters:
    length: float
    height: float
    symmetric: bool
    num_bricks: int
    
    def brick_locations(self) -> list[cq.Location]:
        return []

if __name__ == "__main__" or __name__ == "__cq_main__":
    result = cq.Workplane("XY" ).box(3, 3, 0.5).edges("|Z").fillet(0.125)
    show_object(result)

print(__name__)
