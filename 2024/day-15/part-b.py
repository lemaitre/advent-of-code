#! /usr/bin/env python3

from typing import Iterable

import click

def add_vec(x: tuple[int, int], y: tuple[int, int]) -> tuple[int, int]:
  return (x[0] + y[0], x[1] + y[1])

class Warehouse:
  def __init__(self):
    self.__obstacles = set()
    self.__crates = {}
    self.__bot = (0, 0)
    self.__width = 0
    self.__height = 0

  @property
  def obstacles(self) -> set[tuple[int, int]]:
    return self.__obstacles

  @property
  def crates(self) -> dict[tuple[int, int], tuple[int, int]]:
    return self.__crates
  
  @property
  def bot(self) -> tuple[int, int]:
    return self.__bot

  @bot.setter
  def bot(self, pos: tuple[int, int]):
    i, j = pos
    self.__width = max(self.__width, 2*j + 2)
    self.__height = max(self.__height, i + 1)
    self.__bot = (i, 2*j)

  @property
  def width(Self) -> int:
    return self.__width

  @property
  def height(Self) -> int:
    return self.__height

  def add_obstacle(self, pos: tuple[int, int]):
    i, j = pos
    self.__width = max(self.__width, 2*j + 2)
    self.__height = max(self.__height, i + 1)
    self.__obstacles.add((i, 2*j))
    self.__obstacles.add((i, 2*j + 1))

  def add_crate(self, pos: tuple[int, int]):
    i, j = pos
    self.__width = max(self.__width, 2*j + 2)
    self.__height = max(self.__height, i + 1)
    self.__crates[(i, 2*j)] = (i, 2*j+1)
    self.__crates[(i, 2*j + 1)] = (i, 2*j)

  def try_move(self, dir: str):
    if dir == '^':
      force = (-1, 0)
    elif dir == '>':
      force = (0, 1)
    elif dir == 'v':
      force = (1, 0)
    elif dir == '<':
      force = (0, -1)
    else:
      raise RuntimeError(f"{dir!r} is not a valid direction")

    push_candidates = {self.__bot}
    moving_crates = set()

    while push_candidates:
      candidate = add_vec(push_candidates.pop(), force)
      if candidate in self.__obstacles:
        return
      if crate := self.__crates.get(candidate):
        crate2 = self.__crates[crate]
        if add_vec(crate, force) != crate2:
          push_candidates.add(crate)
        if add_vec(crate2, force) != crate:
          push_candidates.add(crate2)
        moving_crates.add((crate, crate2))
    
    for crate, crate2 in moving_crates:
      try:
        del self.__crates[crate]
        del self.__crates[crate2]
      except KeyError:
        pass
    for crate, crate2 in moving_crates:
      crate = add_vec(crate, force)
      crate2 = add_vec(crate2, force)

      self.__crates[crate] = crate2
      self.__crates[crate2] = crate

    self.__bot = add_vec(self.__bot, force)

  def __str__(self) -> str:
    s = []
    for i in range(self.__height):
      for j in range(self.__width):
        pos = (i, j)
        c = '.'
        if pos in self.__obstacles:
          c = '#'
        if crate := self.__crates.get(pos):
          if pos < crate:
            c = '['
          else:
            c = ']'
        if pos == self.__bot:
          c = '@'
        s.append(c)
      s.append('\n')
    return ''.join(s)

  def __iter__(self) -> Iterable[tuple[int, int]]:
    for crate, crate2 in self.__crates.items():
      if crate < crate2:
        yield crate
      
        




@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  warehouse = Warehouse()

  i = 0
  while (line := input.readline()) != '\n':
    for j, c in enumerate(line[:-1]):
      if c == '#':
        warehouse.add_obstacle((i, j))
      elif c == 'O':
        warehouse.add_crate((i, j))
      elif c == '@':
        warehouse.bot = (i, j)
      elif c != '.':
        raise RuntimeError(f"{c!r} is not a valid cell")
    i += 1
  
  while line := input.readline():
    for c in line[:-1]:
      warehouse.try_move(c)

  print(warehouse)
  s = sum(100*i + j for i, j in warehouse)

  print(s)




if __name__ == '__main__':
  part_b()
