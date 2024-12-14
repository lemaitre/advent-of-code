#! /usr/bin/env python3

import re

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  s = sum(int(match[0]) * int(match[1]) for match in re.findall(r"mul\((\d{1,3}),(\d{1,3})\)", input.read()))

  click.echo(s)


if __name__ == '__main__':
  part_a()
