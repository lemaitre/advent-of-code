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

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
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
  
  while 0 <= pos[0] < A.nrows and 0 <= pos[1] < A.ncols:
    i, j = pos
    if dir == '^':
      i -= 1
    elif dir == '>':
      j += 1
    elif dir == 'v':
      i += 1
    elif dir == '<':
      j -= 1

    if A[i, j] == '#':
      if dir == '^':
        dir = '>'
      elif dir == '>':
        dir = 'v'
      elif dir == 'v':
        dir = '<'
      elif dir == '<':
        dir = '^'
    else:
      A[i, j] = 'X'
      pos = i, j
  
  s = sum(row.count('X') for row in A.rows)

  click.echo(s)





if __name__ == '__main__':
  part_a()
