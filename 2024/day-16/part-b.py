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
def part_b(input: click.File):
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
  visited_grid = np.full(grid.shape + (4,), None, object)

  for i, row in enumerate(grid):
    for j, c in enumerate(row):
      if not c:
        score_grid[i, j, :] = [-1, -1, -1, -1]
      visited_grid[i, j, :] = [set() for _ in range(4)]

  q = PriorityQueue()

  q.put((0, start[0], start[1], 0, set()))

  while q:
    score, i, j, d, visited = q.get()

    # if current cell is an obstacle, cell score will be -1, so is skipped
    # if current cell has already been visited in this direction, cell score would be lower because of priority queue
    if score < score_grid[i, j, d]:
      score_grid[i, j, d] = score
      visited_grid[i, j, d].update(visited, [(i, j)])
      visited = visited_grid[i, j, d]

      si, sj = steps[d]
      q.put((score + 1, i + si, j + sj, d, visited))
      q.put((score + 1000, i, j, (d + 1) % 4, visited))
      q.put((score + 1000, i, j, (d - 1) % 4, visited))
    
    # if score is identical, cell has already been processed, but we still need to update the visited set
    elif score == score_grid[i, j, d]:
      visited_grid[i, j, d].update(visited)


  score = min(score_grid[end[0], end[1], :])
  visited = set()
  for d in range(4):
    if score_grid[end[0], end[1], d] == score:
      visited.update(visited_grid[end[0], end[1], d])

  for i, row in enumerate(grid):
    line = []
    for j, c in enumerate(row):
      if c == 0:
        line.append('#')
      else:
        if (i, j) in visited:
          line.append('O')
        else:
          line.append('.')
    click.echo("".join(line))
        
  
  click.echo(score)
  click.echo(len(visited))



if __name__ == '__main__':
  part_b()
