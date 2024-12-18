#! /usr/bin/env python3

from collections import deque
from itertools import islice

import click
import numpy as np

@click.command()
@click.argument('input', type=click.File('r'))
@click.option('-w', '--width', type=int, default=71)
@click.option('-h', '--height', type=int, default=71)
@click.option('-n', '--nbytes', type=int, default=1024)
def part_a(input: click.File, width: int, height: int, nbytes: int):
  grid = np.full((height, width), 2**31-1, int)
  for line in islice(input, nbytes):
    x, y = (int(c) for c in line.split(','))
    grid[y, x] = -1
  
  queue = deque([(0, 0, 0)])
  while queue:
    s, i, j = queue.popleft()
    if s < grid[i, j]:
      grid[i, j] = s
      if i > 0:
        queue.append((s+1, i-1, j))
      if i < height-1:
        queue.append((s+1, i+1, j))
      if j > 0:
        queue.append((s+1, i, j-1))
      if j < width-1:
        queue.append((s+1, i, j+1))

  mapping = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for row in grid:
    line = []
    for cell in row:
      if cell == -1:
        c = '#'
      elif cell == 2**31 - 1:
        c = '.'
      elif cell < len(mapping):
        c = mapping[cell]
      else:
        c = '+'
      line.append(c)
    click.echo("".join(line))
  
  steps = grid[height-1, width-1]
  click.echo(steps)

  


if __name__ == '__main__':
  part_a()
