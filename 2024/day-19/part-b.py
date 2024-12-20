#! /usr/bin/env python3

from typing import Iterable

import click

class Trie:
  def __init__(self):
    self.data = {}
  
  def add(self, string: str):
    d = self.data
    for c in string:
      d = d.setdefault(c, {})
    d[None] = None
  
  def partial_match(self, string: str) -> Iterable[str]:
    d = self.data
    for i, c in enumerate(string):
      if None in d:
        yield string[:i]
      if c not in d:
        break
      d = d[c]
    else:
      if None in d:
        yield string
  
  def combination_match(self, string: str, cache = None) -> int:
    if cache is None:
      cache = {}
    if string in cache:
      return cache[string]

    s = 0
    string_len = len(string)
    for partial in self.partial_match(string):
      partial_len = len(partial)
      if partial_len == string_len:
        s += 1
      s += self.combination_match(string[partial_len:], cache)
    
    cache[string] = s

    return s
  
  def __in__(self, string: str) -> bool:
    return self.match(string)

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  trie = Trie()

  for towel in sorted((t.strip() for t in input.readline().split(',')), key = lambda t: (len(t), t)):
    trie.add(towel)
  
  input.readline()

  s = 0
  for i, line in enumerate(input):
    line = line[:-1]
    s += trie.combination_match(line)
  
  click.echo(s)

if __name__ == '__main__':
  part_b()
