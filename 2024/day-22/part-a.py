#! /usr/bin/env python3

import click
import numpy as np

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  secret = np.array([int(line) for line in input], np.uint32)

  for i in range(2000):
    secret = (secret ^ (secret << 6)) & 0xffffff
    secret = (secret ^ (secret >> 5)) & 0xffffff
    secret = (secret ^ (secret << 11)) & 0xffffff
  
  click.echo(secret.sum())

if __name__ == '__main__':
  part_a()
