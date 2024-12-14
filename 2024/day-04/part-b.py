#! /usr/bin/env python3

from typing import Iterable
import re

import click

class Grid:
  def __init__(self, rows: Iterable[str]):
    self.rows = list(row.strip() for row in rows)

  def __getitem__(self, pos) -> str:
    return self.rows[pos]

  @property
  def nrows(self) -> int:
    return len(self.rows)

  @property
  def ncols(self) -> int:
    return len(self.rows[0])
  
  def __str__(self) -> str:
    return "\n".join(self.rows)

def pair_is_ms(a: str, b: str) -> bool:
  return min(a, b) == 'M' and max(a, b) == 'S'

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  grid = Grid(input.readlines())

  s = 0

  for i in range(1, grid.nrows - 1):
    for j in range(1, grid.ncols - 1):
      if grid[i][j] == 'A' and pair_is_ms(grid[i-1][j-1], grid[i+1][j+1]) and pair_is_ms(grid[i-1][j+1], grid[i+1][j-1]):
        s += 1

  click.echo(s)


if __name__ == '__main__':
  part_b()
