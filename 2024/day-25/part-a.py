#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  locks = []
  keys = []
  has_input = True
  while has_input:
    header = input.readline()
    heights = [0] * 5
    for i in range(5):
      for j, c in enumerate(input.readline()):
        if c == header[0]:
          heights[j] = i + 1
    if header[0] == '#':
      locks.append(heights)
    else:
      keys.append([5 - h for h in heights])
    input.readline()
    has_input = bool(input.readline())
  
  s = 0
  for lock in locks:
    for key in keys:
      if all(l + k <= 5 for l, k in zip(lock, key)):
        s += 1
  
  click.echo(s)

if __name__ == '__main__':
  part_a()
