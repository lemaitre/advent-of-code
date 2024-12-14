#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  antennas: dict[str, set[tuple[int,int]]] = {}
  antinodes: set[tuple[int, int]] = set()

  width = 0
  height = 0
  for i, line in enumerate(input):
    line = line.strip()
    height = i + 1
    width = max(width, len(line))
    for j, c in enumerate(line):
      if c == '.':
        continue
      interfering = antennas.setdefault(c, set())
      for i2, j2 in interfering:
        di, dj = i2 - i, j2 - j
        antinodes.add((i - di, j - dj))
        antinodes.add((i2 + di, j2 + dj))
      interfering.add((i, j))
  
  s = 0
  for i, j in antinodes:
    if 0 <= i < height and 0 <= j < width:
      s += 1
  click.echo(s)


if __name__ == '__main__':
  part_a()
