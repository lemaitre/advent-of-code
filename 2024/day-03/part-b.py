#! /usr/bin/env python3

import re

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  s = 0

  for part in input.read().split(r"do()"):
    part = part.split(r"don't()", 2)[0]

    print(f">> {part}")

    s += sum(int(match[0]) * int(match[1]) for match in re.findall(r"mul\((\d{1,3}),(\d{1,3})\)", part))

  click.echo(s)

if __name__ == '__main__':
  part_b()
