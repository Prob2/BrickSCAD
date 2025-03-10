from openscad import *;

def wall_points(length, height, brick_length, brick_width, invert_odd):
    whole_brick_length = length - brick_width;
    whole_brick_count = round(whole_brick_length / brick_length
let (whole_brick_length = length - brick_width)
    let (whole_brick_count = round(whole_brick_length / brick_length))
      let (i_brick_length = whole_brick_length / whole_brick_count)
        let (row_brick_count = whole_brick_count)
          let (row_count = round(height / brick_height))
            let (i_brick_height = height / row_count)
              flatten([
                for (r = [0:row_count - 1])
                  row_points(row_brick_count, i_brick_length, r * i_brick_height, i_brick_height, (r % 2 == 0) == invert_odd), 
              ]);
