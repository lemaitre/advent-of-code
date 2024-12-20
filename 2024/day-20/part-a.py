#! /usr/bin/env python3

from collections import deque

import numpy as np
import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
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
  for i in range(1, grid.shape[0] - 1):
    for j in range(1, grid.shape[1] - 1):
      c = grid[i, j]
      if c < 0:
        a = grid[i - 1, j]
        b = grid[i + 1, j]
        c = grid[i, j - 1]
        d = grid[i, j + 1]

        a, b = min(a, b), max(a, b)
        c, d = min(c, d), max(c, d)

        if a >= 0 and b >= 0 and b - a - 2 >= 100:
          s += 1
        if c >= 0 and d >= 0 and d - c - 2 >= 100:
          s += 1

  click.echo(s)

if __name__ == '__main__':
  part_a()
