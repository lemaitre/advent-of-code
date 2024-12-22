#! /usr/bin/env python3

from typing import Iterable
from functools import cache
import click

Numpad = [
  "#####",
  "#789#",
  "#456#",
  "#123#",
  "##0A#",
  "#####",
]

NumpadPos = {
  'A': (3, 2),
  '0': (3, 1),
  '1': (2, 0),
  '2': (2, 1),
  '3': (2, 2),
  '4': (1, 0),
  '5': (1, 1),
  '6': (1, 2),
  '7': (0, 0),
  '8': (0, 1),
  '9': (0, 2),
}
def numpad_pos(key: str) -> tuple[int, int]:
  return NumpadPos[key]

def numpad_move(src: str, dst: str) -> str:
  i1, j1 = numpad_pos(src)
  i2, j2 = numpad_pos(dst)

  if i1 < i2:
    v = 'v' * (i2 - i1)
  elif i1 > i2:
    v = '^' * (i1 - i2)
  else:
    v = ''

  if j1 < j2:
    h = '>' * (j2 - j1)
    hfirst = False
  elif j1 > j2:
    h = '<' * (j1 - j2)
    hfirst = True
  else:
    h = ''
  
  if h == '':
    return v
  elif v == '':
    return h
  else:
    if max(i1, i2) != 3 or min(j1, j2) != 0:
      # both works, but the other requires more steps when recursing
      if hfirst:
        return h + v
      else:
        return v + h
    elif i1 == 3:
      return v + h
    else:
      return h + v

Dirpad = [
  "#####",
  "##^A#",
  "#<v>#",
  "#####",
]

DirpadMove = {
  ('A', 'A'): '',
  ('A', '^'): '<',
  ('A', '>'): 'v',
  ('A', 'v'): '<v', # 'v<' is also possible, but requires more steps when recursing
  ('A', '<'): 'v<<',
  ('^', '^'): '',
  ('^', 'A'): '>',
  ('^', '>'): 'v>', # '>v' is also possible, but requires more steps when recursing
  ('^', '<'): 'v<',
  ('>', '>'): '',
  ('>', 'A'): '^',
  ('>', '^'): '<^', # '^<' is also possible, but requires more steps when recursing
  ('>', 'v'): '<',
  ('v', 'v'): '',
  ('v', 'A'): '^>', # '>^' is also possible, but requires more steps when recursing
  ('v', '>'): '>',
  ('v', '<'): '<',
  ('<', '<'): '',
  ('<', 'A'): '>>^',
  ('<', '^'): '>^',
  ('<', 'v'): '>',
}

def dirpad_move(src: str, dst: str) -> str:
  return DirpadMove.get((src, dst), '')

dirpad_steps = {}

for (prev, target), seq in DirpadMove.items():
  dirpad_steps[0, prev, target] = 1

for i in range(25):
  for (prev, target), seq in DirpadMove.items():
    src = 'A'
    s = 0
    for key in seq:
      s += dirpad_steps[i, src, key]
      src = key
    s += dirpad_steps[i, src, 'A']
    dirpad_steps[i + 1, prev, target] = s





def numpad_path(code: str) -> str:
  prev = 'A'
  path = []
  for key in code:
    path.append(numpad_move(prev, key))
    path.append('A')
    prev = key
  return "".join(path)

def path_len(code: str) -> int:
  n = 25
  seq = numpad_path(code)
  prev = 'A'
  s = 0
  for key in seq:
    s += dirpad_steps[n, prev, key]
    prev = key
  return s

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  s = 0
  for line in input:
    s += path_len(line[:-1]) * int(line[:-2])
  
  click.echo(s)
  


if __name__ == '__main__':
  part_b()
