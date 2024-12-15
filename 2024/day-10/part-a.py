#! /usr/bin/env python3

import click
import numpy as np

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  grid = np.array([[int(c) for c in row if c.isdigit()] for row in input], dtype=np.int8)

  zeros = []
  nines = []

  for i, row in enumerate(grid):
    for j, c in enumerate(row):
      if c == 0:
        zeros.append((i, j))
      elif c == 9:
        nines.append((i, j))

  reachable = np.zeros(grid.shape, object)

  for i, pos in enumerate(nines):
    reachable[pos] = 1 << i

  for _ in range(9):
    for i, row in enumerate(grid):
      for j, c in enumerate(row):
        if i > 0:
          if grid[i-1, j] - c == 1:
            reachable[i, j] |= reachable[i-1, j]
        if i < grid.shape[0]-1:
          if grid[i+1, j] - c == 1:
            reachable[i, j] |= reachable[i+1, j]
        if j > 0:
          if grid[i, j-1] - c == 1:
            reachable[i, j] |= reachable[i, j-1]
        if j < grid.shape[1]-1:
          if grid[i, j+1] - c == 1:
            reachable[i, j] |= reachable[i, j+1]
  
  s = 0

  for pos in zeros:
    s += reachable[pos].bit_count()

  click.echo(s)

if __name__ == '__main__':
  part_a()
