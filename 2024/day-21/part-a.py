#! /usr/bin/env python3

from typing import Iterable
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

def numpad_move(src: str, dst: str) -> Iterable[str]:
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
  elif j1 > j2:
    h = '<' * (j1 - j2)
  else:
    h = ''
  
  if h == '':
    yield v
  elif v == '':
    yield h
  else:
    if max(i1, i2) != 3 or min(j1, j2) != 0:
      yield v + h
      yield h + v
    elif i1 == 3:
      yield v + h
    else:
      yield h + v

Dirpad = [
  "#####",
  "##^A#",
  "#<v>#",
  "#####",
]

DirpadPos = {
  'A': (0, 2),
  '^': (0, 1),
  '<': (1, 0),
  'v': (1, 1),
  '>': (1, 2),
}
def dirpad_pos(key: str) -> tuple[int, int]:
  return DirpadPos[key]

def dirpad_move(src: str, dst: str) -> Iterable[str]:
  i1, j1 = dirpad_pos(src)
  i2, j2 = dirpad_pos(dst)

  if i1 < i2:
    v = 'v' * (i2 - i1)
  elif i1 > i2:
    v = '^' * (i1 - i2)
  else:
    v = ''

  if j1 < j2:
    h = '>' * (j2 - j1)
  elif j1 > j2:
    h = '<' * (j1 - j2)
  else:
    h = ''
  
  if h == '':
    yield v
  elif v == '':
    yield h
  else:
    if min(i1, i2) != 0 or min(j1, j2) != 0:
      yield v + h
      yield h + v
    elif i1 == 0:
      yield v + h
    else:
      yield h + v

def numpad_path(code: str, key: str = 'A') -> Iterable[str]:
  if not code:
    yield ''
  else:
    for move in numpad_move(key, code[0]):
      for candidate in numpad_path(code[1:], code[0]):
        yield f"{move}A{candidate}"

def dirpad_path(code: str, key: str = 'A') -> Iterable[str]:
  if not code:
    yield ''
  else:
    for move in dirpad_move(key, code[0]):
      for candidate in dirpad_path(code[1:], code[0]):
        yield f"{move}A{candidate}"

def path(code: str) -> str:
  min_seqs = None
  for seq0 in numpad_path(code):
    for seq1 in dirpad_path(seq0):
      for seq2 in dirpad_path(seq1):
        if min_seqs is None or len(seq2) < len(min_seqs[2]):
          min_seqs = (seq0, seq1, seq2)
  return min_seqs[2]

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  s = 0
  for line in input:
    s += len(path(line[:-1])) * int(line[:-2])
  
  click.echo(s)
  


if __name__ == '__main__':
  part_a()
