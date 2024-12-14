#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  A = {}
  B = {}

  for line in input.readlines():
    a, b = line.split()
    a = int(a)
    b = int(b)

    A[a] = A.get(a, 0) + 1
    B[b] = B.get(b, 0) + 1

  s = sum(k * v * B.get(k, 0) for k, v in A.items())

  click.echo(s)

if __name__ == '__main__':
  part_b()
