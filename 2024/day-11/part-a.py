#! /usr/bin/env python3

from typing import Iterable

import click

class Stones:
  def __init__(self, stones: Iterable[str]):
    self.stones = [stone for stone in stones]

  @staticmethod
  def blink_stone(stone: str) -> Iterable[str]:
    if stone == '0':
      yield '1'
    else:
      n = len(stone)
      if n % 2 == 0:
        yield str(int(stone[:n//2]))
        yield str(int(stone[n//2:]))
      else:
        yield str(int(stone) * 2024)

  def blink(self) -> 'Stones':
    return Stones(b for a in self.stones for b in Stones.blink_stone(a))

  def __str__(self) -> str:
    return " ".join(self.stones)

  def __len__(self) -> int:
    return len(self.stones)


@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  stones = Stones(input.read().split())

  n = 25
  for i in range(n):
    stones = stones.blink()

  click.echo(len(stones))

if __name__ == '__main__':
  part_a()
