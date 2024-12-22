#! /usr/bin/env python3

from collections import defaultdict

import click
import numpy as np

MOD = 19 ** 4

def next_secret(secret):
  secret = (secret ^ (secret << 6)) & 0xffffff
  secret = (secret ^ (secret >> 5)) & 0xffffff
  secret = (secret ^ (secret << 11)) & 0xffffff
  return secret

def get_price(secret):
  return secret % 10

def get_key(key, diff):
  return ((key * 19) % MOD) + diff + 9


@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  secret = np.array([int(line) for line in input], np.int32)
  price = get_price(secret)
  key = np.zeros(price.shape, np.int32)

  for i in range(3):
    secret = next_secret(secret)
    new_price = get_price(secret)
    key = get_key(key, new_price - price)
    price = new_price
  
  seen = np.zeros((len(secret), ))
  seen = [set() for _ in range(len(secret))]
  sells = defaultdict(int)
  
  for i in range(3, 2000):
    secret = next_secret(secret)
    new_price = get_price(secret)
    key = get_key(key, new_price - price)
    price = new_price

    for k, p, s in zip(key, price, seen):
      if k not in s:
        s.add(k)
        sells[k] += p
  
  click.echo(max(sells.values()))


if __name__ == '__main__':
  part_b()
