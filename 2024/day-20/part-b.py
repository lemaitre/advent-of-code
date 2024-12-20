#! /usr/bin/env python3

from collections import deque

import numpy as np
import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  grid = []
  start = (0, 0)
  end = (0, 0)

  for i, line in enumerate(input):
    line = line[:-1]
    grid.append([c == '#' and -1 or 2**31-1 for c in line])
    for j, c in enumerate(line):
      if c == 'S':
        start = (i, j)
      if c == 'E':
        stop = (i, j)
  
  grid = np.array(grid, int)

  q = deque()
  q.append((0, start))

  while q:
    step, (i, j) = q.popleft()
    if step < grid[i, j]:
      grid[i, j] = step
      if i > 1:
        q.append((step + 1, (i - 1, j)))
      if i < grid.shape[0] - 1:
        q.append((step + 1, (i + 1, j)))
      if j > 1:
        q.append((step + 1, (i, j - 1)))
      if j < grid.shape[1] - 1:
        q.append((step + 1, (i, j + 1)))
  
  s = 0
  for i1 in range(1, grid.shape[0] - 1):
    for i2 in range(1, grid.shape[0] - 1):
      di = max(i1, i2) - min(i1, i2)
      if di > 20:
        continue
      for j1 in range(1, grid.shape[1] - 1):
        for j2 in range(1, grid.shape[1] - 1):
          dj = max(j1, j2) - min(j1, j2)
          if di + dj > 20:
            continue
          c1 = grid[i1, j1]
          c2 = grid[i2, j2]
          if 0 <= c1 < c2 < 2**31-1:
            saved = c2 - c1 - (di + dj)
            if saved >= 100:
              s += 1

  click.echo(s)

if __name__ == '__main__':
  part_b()
