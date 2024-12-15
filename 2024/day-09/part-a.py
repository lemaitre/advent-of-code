#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  segments = [int(x) for x in input.read().strip()]

  n = len(segments)
  i = 0
  j = n - 1

  checksum = 0
  x = 0
  while i < j:
    for _ in range(segments[i]):
      checksum += (i // 2) * x
      x += 1
    for _ in range(segments[i+1]):
      checksum += (j // 2) * x
      segments[j] -= 1
      if segments[j] == 0:
        j -= 2
        if i >= j:
          break
      x += 1
    i += 2
  
  if i == j:
    for _ in range(segments[i]):
      checksum += (i // 2) * x
      disk.append(i // 2)
      x += 1
    
  click.echo(checksum)

if __name__ == '__main__':
  part_a()
