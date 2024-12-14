#! /usr/bin/env python3

from typing import Iterable, Iterator

import click

class Grid:
  def __init__(self, rows: Iterable[str]):
    self.rows = [[c for c in row.strip()] for row in rows]
  
  @property
  def nrows(self) -> int:
    return len(self.rows)
  
  @property
  def ncols(self) -> int:
    return len(self.rows[0])
  
  def __getitem__(self, pos: tuple[int, int]) -> str:
    i, j = pos

    if i < 0 or i >= self.nrows:
      return '.'
    row = self.rows[i]

    if j < 0 or j >= self.ncols:
      return '.'
    
    return row[j]
  def __setitem__(self, pos: tuple[int, int], val: str):
    i, j = pos

    if i < 0 or i >= self.nrows:
      return
    row = self.rows[i]

    if j < 0 or j >= self.ncols:
      return
    
    row[j] = val

  def __str__(self) -> str:
    return "\n".join("".join(row) for row in self.rows)

  def __iter__(self) -> Iterator[str]:
    for row in self.rows:
      yield "".join(row)

  def is_looping(self, pos: tuple[int, int], dir: str) -> bool:
    seen = {}
    while 0 <= pos[0] < self.nrows and 0 <= pos[1] < self.ncols:
      candidate = seen.setdefault(pos, set())
      if dir in candidate:
        return True
      candidate.add(dir)

      i, j = pos
      if dir == '^':
        i -= 1
      elif dir == '>':
        j += 1
      elif dir == 'v':
        i += 1
      elif dir == '<':
        j -= 1

      if self[i, j] in '#O':
        if dir == '^':
          dir = '>'
        elif dir == '>':
          dir = 'v'
        elif dir == 'v':
          dir = '<'
        elif dir == '<':
          dir = '^'
      else:
        pos = i, j

    return False

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  A = Grid(input)

  pos = None
  dir = None

  for i in range(0, A.nrows):
    for j in range(0, A.ncols):
      x = A[i, j]
      if x in '^>v<':
        pos = i, j
        dir = x
        A[i, j] = 'X'
  
  s = 0
  for i in range(0, A.nrows):
    for j in range(0, A.ncols):
      click.echo((i, j))
      if A[i, j] != '.':
        continue
      B = Grid(A)
      B[i, j] = 'O'

      if B.is_looping(pos, dir):
        s += 1

  click.echo(s)


if __name__ == '__main__':
  part_b()
