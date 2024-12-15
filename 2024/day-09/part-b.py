#! /usr/bin/env python3

import click
import portion as P

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  file_mapping = {}
  files = []

  x = 0
  for i, segment in enumerate(input.read().strip()):
    click.echo(f"generate {i}")
    segment = int(segment)
    if i % 2 == 0:
      file = P.closedopen(x, x + segment)
      file_mapping[i // 2] = file
      files.append(file)
    x += segment

  free_space = P.closedopen(0, x) - P.Interval(*files)

  for i in reversed(range(len(files))):
    file = files[i]
    click.echo(f"move {i}/{len(files)}")
    file_length = file.upper - file.lower
    for free_range in free_space:
      if file <= free_range:
        break
      free_length = free_range.upper - free_range.lower

      if free_length >= file_length:
        new_file = P.closedopen(free_range.lower, free_range.lower + file_length)
        file_mapping[i] = new_file
        free_space -= new_file
        free_space |= file
        break
  
  checksum = 0
  for file_id, file in file_mapping.items():
    for x in P.iterate(file, 1):
      checksum += file_id * x

  click.echo(checksum)

if __name__ == '__main__':
  part_b()
