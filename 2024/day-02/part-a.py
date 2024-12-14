#! /usr/bin/env python3

from typing import Iterable
from itertools import pairwise

import click

class Report:
  def __init__(self, levels: Iterable[str | int]):
    self.levels = [int(level) for level in levels]
  
  def diffs(self) -> Iterable[int]:
    return (b - a for a, b in pairwise(self.levels))

  def is_safe(self) -> bool:
    a = min(self.diffs())
    b = max(self.diffs())

    return (a >= -3 and b <= -1) or (a >= 1 and b <= 3)

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  nsafe = 0
  for line in input.readlines():
    report = Report(line.split())

    if report.is_safe():
      nsafe += 1
      
  click.echo(nsafe)

if __name__ == '__main__':
  part_a()
