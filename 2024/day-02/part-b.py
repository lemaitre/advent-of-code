#! /usr/bin/env python3

from typing import Iterable
from itertools import chain, pairwise

import click

class Report:
  def __init__(self, levels: Iterable[str | int]):
    self.levels = [int(level) for level in levels]
  
  def diffs(self) -> Iterable[int]:
    return (b - a for a, b in pairwise(self.levels))
  
  def dampened_reports(self) -> Iterable['Report']:
    n = len(self.levels)
    yield self

    for i in range(0, n):
      yield Report(chain(self.levels[:i], self.levels[i+1:]))

  def is_safe(self) -> bool:
    a = min(self.diffs())
    b = max(self.diffs())

    return (a >= -3 and b <= -1) or (a >= 1 and b <= 3)

  def __repr__(self) -> str:
    return f"Report({self.levels!r})"

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  nsafe = 0
  for line in input.readlines():
    report = Report(line.split())

    if any(r.is_safe() for r in report.dampened_reports()):
      nsafe += 1
      
  click.echo(nsafe)

if __name__ == '__main__':
  part_b()
