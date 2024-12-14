#! /usr/bin/env python3

from collections import defaultdict
from itertools import pairwise

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  after = defaultdict(set)
  ordering = True

  s = 0

  for line in input:
    if line == '\n':
      ordering = False
    elif ordering:
      a, b = (int(x) for x in line.split('|'))
      after[a].add(b)
    else:
      line = [int(x) for x in line.split(',')]
      for a, b in pairwise(line):
        if a in after[b]:
          break
      else:
        s += line[len(line)//2]


  click.echo(s)

if __name__ == '__main__':
  part_a()
