#! /usr/bin/env python3

from collections import defaultdict
import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  stones = defaultdict(int)
  for stone in input.read().split():
    stones[int(stone)] += 1

  n = 75

  for i in range(n):
    new_stones = defaultdict(int)
    for stone, nstone in stones.items():
      if stone == 0:
        new_stones[1] += nstone
      else:
        sstone = str(stone)
        lstone = len(sstone)
        if lstone % 2 == 0:
          new_stones[int(sstone[:lstone//2])] += nstone
          new_stones[int(sstone[lstone//2:])] += nstone
        else:
          new_stones[stone*2024] += nstone
    stones = new_stones

  print(sum(stones.values()))

if __name__ == '__main__':
  part_b()
