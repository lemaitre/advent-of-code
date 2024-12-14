#! /usr/bin/env python3

import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  for line in input:
    click.echo(line)

if __name__ == '__main__':
  part_b()
