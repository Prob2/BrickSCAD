import unittest

from wall import *

class TestRow(unittest.TestCase):
    def test_non_symmetric_odd(self):
        row = RowParameters(length=28, height=3, brick_length=6, half_brick_length=4, num_bricks=5, odd=True, symmetric=False)
        self.assertEqual(row.brick_widths(), [6, 6, 6, 6, 4])
    def test_non_symmetric_even(self):
        row = RowParameters(length=28, height=3, brick_length=6, half_brick_length=4, num_bricks=5, odd=False, symmetric=False)
        self.assertEqual(row.brick_widths(), [4, 6, 6, 6, 6])
    def test_symmetric_odd(self):
        row = RowParameters(length=30, height=3, brick_length=6, half_brick_length=3, num_bricks=5, odd=True, symmetric=True)
        self.assertEqual(row.brick_widths(), [3, 6, 6, 6, 6, 3])
    def test_symmetric_even(self):
        row = RowParameters(length=30, height=3, brick_length=6, half_brick_length=3, num_bricks=5, odd=False, symmetric=True)
        self.assertEqual(row.brick_widths(), [6, 6, 6, 6, 6])

if __name__ == '__main__':
    unittest.main()
