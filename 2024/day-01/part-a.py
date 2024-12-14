#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  A = []
  B = []

  for line in input.readlines():
    a, b = line.split()
    a = int(a)
    b = int(b)
    A.append(a)
    B.append(b)

  A.sort()
  B.sort()

  s = sum(max(a, b) - min(a, b) for a, b in zip(A, B))

  click.echo(s)

if __name__ == '__main__':
  part_a()
