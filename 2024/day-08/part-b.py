#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  antennas: dict[str, set[tuple[int,int]]] = {}
  antinodes: set[tuple[int, int]] = set()

  width = 0
  height = 0
  for i, line in enumerate(input):
    line = line.strip()
    width = max(width, len(line))
    height = max(height, width, i + 1)
    for j, c in enumerate(line):
      if c == '.':
        continue
      interfering = antennas.setdefault(c, set())
      for i2, j2 in interfering:
        di, dj = i2 - i, j2 - j
        k = 0
        while 0 <= i - k*di < height and 0 <= j - k*dj < width:
          antinodes.add((i - k*di, j - k*dj))
          k += 1
        k = 0
        while 0 <= i2 + k*di < height and 0 <= j2 + k*dj < width:
          antinodes.add((i2 + k*di, j2 + k*dj))
          k += 1
      interfering.add((i, j))
  
  click.echo(len(antinodes))


if __name__ == '__main__':
  part_b()
