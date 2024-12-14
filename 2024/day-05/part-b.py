#! /usr/bin/env python3

from collections import defaultdict
from itertools import pairwise
from functools import cmp_to_key

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  before = defaultdict(set)
  after = defaultdict(set)
  ordering = True

  s = 0

  def cmp(a: int, b: int) -> bool:
    if b in after[a]:
      return -1
    if a in after[b]:
      return 1
    return 0

  for line in input:
    if line == '\n':
      ordering = False
    elif ordering:
      a, b = (int(x) for x in line.split('|'))
      after[a].add(b)
      before[b].add(a)
    else:
      line = [int(x) for x in line.split(',')]
      line_sorted = sorted(line[:], key=cmp_to_key(cmp))

      if line != line_sorted:
        s += line_sorted[len(line_sorted)//2]


  click.echo(s)

if __name__ == '__main__':
  part_b()
