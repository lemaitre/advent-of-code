#! /usr/bin/env python3

from operator import add, mul

import click

def concat(a: int, b: int):
  return int(f"{a}{b}")

def count_solutions(target: int, acc: int, coeffs: list[int]) -> int:
  if acc > target:
    return 0

  if len(coeffs) == 0:
    if target == acc:
      return 1
    else:
      return 0

  [head, *tail] = coeffs

  count = 0
  for op in [add, mul, concat]:
    count += count_solutions(target, op(acc, head), tail)

  return count


@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  s = 0
  for line in input:
    target, line = line.split(': ')
    target = int(target)
    [acc, *coeffs] = [int(x) for x in line.split()]

    if count_solutions(target, acc, coeffs) > 0:
      s += target

  click.echo(s)

if __name__ == '__main__':
  part_b()
