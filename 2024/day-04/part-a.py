#! /usr/bin/env python3

from typing import Iterable
import re

import click

class Grid:
  def __init__(self, rows: Iterable[str]):
    self.rows = list(row.strip() for row in rows)

  def iter_rows(self) -> Iterable[str]:
    return self.rows

  def iter_cols(self) -> Iterable[str]:
    return ("".join(col) for col in zip(*self.rows))

  def iter_diag1(self) -> Iterable[str]:
    nrows = len(self.rows)
    ncols = len(self.rows[0])

    for k in range(1 - nrows, ncols):
      if k < 0:
        i = -k
        j = 0
      else:
        j = k
        i = 0
      
      s = ""
      while i < nrows and j < ncols:
        s += self.rows[i][j]
        i += 1
        j += 1
      yield s
  
  def iter_diag2(self) -> Iterable[str]:
    nrows = len(self.rows)
    ncols = len(self.rows[0])

    for k in range(1 - nrows, ncols):
      if k <= 0:
        i = -k
        j = 0
      else:
        j = k
        i = nrows - 1
      
      s = ""
      while i >= 0 and j < ncols:
        s += self.rows[i][j]
        i -= 1
        j += 1
      yield s

  def iter_all(self) -> Iterable[str]:
    for iter in (self.iter_rows, self.iter_cols, self.iter_diag1, self.iter_diag2):
      yield from iter()
  
  def __str__(self) -> str:
    return "\n".join(self.rows)
  

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  grid = Grid(input.readlines())

  s = 0
  
  for line in grid.iter_all():
    s += len(re.findall("XMAS", line))
    s += len(re.findall("SAMX", line))

  click.echo(s)


if __name__ == '__main__':
  part_a()
