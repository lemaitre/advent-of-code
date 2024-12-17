#! /usr/bin/env python3

import click
import numpy as np
import heapq

directions = ['>', 'v', '<', '^']
direction_map = {'>': 0, 'v': 1, '<': 2, '^': 3}
steps = [(0, 1), (1, 0), (0, -1), (-1, 0)]

class PriorityQueue:
  def __init__(self):
    self.__heap = []
  
  def put(self, x):
    heapq.heappush(self.__heap, x)

  def get(self):
    return heapq.heappop(self.__heap)

  def __bool__(self) -> bool:
    return bool(self.__heap)

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  grid = []
  start = (0, 0)
  end = (0, 0)
  for i, line in enumerate(input):
    grid.append([c != '#' and 1 or 0 for c in line[:-1]])
    try:
      j = line.index('S')
      start = (i, j)
    except ValueError:
      pass
    try:
      j = line.index('E')
      end = (i, j)
    except ValueError:
      pass

  grid = np.array(grid, dtype=np.uint8)
  score_grid = np.full(grid.shape + (4,), 2**63-1, np.int64)

  for i, row in enumerate(grid):
    for j, c in enumerate(row):
      if not c:
        score_grid[i, j, :] = [-1, -1, -1, -1]

  q = PriorityQueue()

  q.put((0, start[0], start[1], 0))

  while q:
    score, i, j, d = q.get()

    # if current cell is an obstacle, cell score will be -1, so is skipped
    # if current cell has already been visited in this direction, cell score would be lower because of priority queue
    if score < score_grid[i, j, d]:
      score_grid[i, j, d] = score
      si, sj = steps[d]
      q.put((score + 1, i + si, j + sj, d))
      q.put((score + 1000, i, j, (d + 1) % 4))
      q.put((score + 1000, i, j, (d - 1) % 4))

  click.echo(min(score_grid[end[0], end[1], :]))


if __name__ == '__main__':
  part_a()
