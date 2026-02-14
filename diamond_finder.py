#!/usr/bin/env python3
"""
Diamond Finder - A utility to discover and analyze diamond patterns
"""

import random
from typing import List, Tuple


class DiamondFinder:
    """Class to find and analyze diamond patterns in a grid"""
    
    def __init__(self, grid_size: int = 10):
        self.grid_size = grid_size
        self.grid = self._generate_grid()
    
    def _generate_grid(self) -> List[List[str]]:
        """Generate a random grid with diamonds and rocks"""
        grid = []
        for i in range(self.grid_size):
            row = []
            for j in range(self.grid_size):
                # 10% chance of diamond, rest are rocks
                element = '💎' if random.random() < 0.1 else '🪨'
                row.append(element)
            grid.append(row)
        return grid
    
    def display_grid(self):
        """Display the grid"""
        print("\n" + "=" * (self.grid_size * 3))
        for row in self.grid:
            print(" ".join(row))
        print("=" * (self.grid_size * 3) + "\n")
    
    def find_diamonds(self) -> List[Tuple[int, int]]:
        """Find all diamond positions in the grid"""
        diamonds = []
        for i, row in enumerate(self.grid):
            for j, element in enumerate(row):
                if element == '💎':
                    diamonds.append((i, j))
        return diamonds
    
    def calculate_diamond_value(self, position: Tuple[int, int]) -> int:
        """
        Calculate the value of a diamond based on its position.
        Diamonds closer to the center are more valuable.
        """
        row, col = position
        center = self.grid_size / 2
        # Calculate distance from center using Manhattan distance
        distance = abs(row - center) + abs(col - center)
        # Base value is 100, decreases by 5 for each unit away from center
        value = max(10, 100 - int(distance * 5))
        return value
    
    def calculate_total_value(self) -> int:
        """Calculate the total value of all diamonds in the grid"""
        diamonds = self.find_diamonds()
        total_value = sum(self.calculate_diamond_value(pos) for pos in diamonds)
        return total_value


def main():
    """Main function to run the diamond finder"""
    print("🔍 Gemini Diamond Finder v1.0")
    print("=" * 40)
    
    finder = DiamondFinder(grid_size=8)
    finder.display_grid()
    
    diamonds = finder.find_diamonds()
    print(f"Found {len(diamonds)} diamonds at positions:")
    for pos in diamonds:
        value = finder.calculate_diamond_value(pos)
        print(f"  - Row {pos[0]}, Column {pos[1]} (Value: {value})")
    
    total_value = finder.calculate_total_value()
    print(f"\n💰 Total value of diamonds found: {total_value}")
    print("=" * 40)


if __name__ == "__main__":
    main()
