#! /usr/bin/env python3

import click

def add_vec(x: tuple[int, int], y: tuple[int, int]) -> tuple[int, int]:
  return (x[0] + y[0], x[1] + y[1])

class Warehouse:
  def __init__(self):
    self.__obstacles = set()
    self.__crates = set()
    self.__bot = (0, 0)
    self.__width = 0
    self.__height = 0

  @property
  def obstacles(self) -> set[tuple[int, int]]:
    return self.__obstacles

  @property
  def crates(self) -> set[tuple[int, int]]:
    return self.__crates
  
  @property
  def bot(self) -> tuple[int, int]:
    return self.__bot

  @bot.setter
  def bot(self, pos: tuple[int, int]):
    i, j = pos
    self.__width = max(self.__width, j + 1)
    self.__height = max(self.__height, i + 1)
    self.__bot = (i, j)

  @property
  def width(Self) -> int:
    return self.__width

  @property
  def height(Self) -> int:
    return self.__height

  def add_obstacle(self, pos: tuple[int, int]):
    i, j = pos
    self.__width = max(self.__width, j + 1)
    self.__height = max(self.__height, i + 1)
    self.__obstacles.add((i, j))

  def add_crate(self, pos: tuple[int, int]):
    i, j = pos
    self.__width = max(self.__width, j + 1)
    self.__height = max(self.__height, i + 1)
    self.__crates.add((i, j))

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

    moving_crates = []
    pos = add_vec(self.__bot, force)
    while pos in self.__crates:
      moving_crates.append(pos)
      pos = add_vec(pos, force)
    
    if pos not in self.__obstacles:
      if moving_crates:
        self.__crates.remove(moving_crates[0])
        self.__crates.add(pos)
      self.__bot = add_vec(self.__bot, force)

  def __str__(self) -> str:
    s = []
    for i in range(self.__height):
      for j in range(self.__width):
        pos = (i, j)
        c = '.'
        if pos in self.__obstacles:
          c = '#'
        if pos in self.__crates:
          c = 'O'
        if pos == self.__bot:
          c = '@'
        s.append(c)
      s.append('\n')
    return ''.join(s)
      
        




@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
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
  s = sum(100*i + j for i, j in warehouse.crates)

  print(s)




if __name__ == '__main__':
  part_a()
