#! /usr/bin/env python3

import re

import click
class Cpu:
  def __init__(self, a: int, b: int, c: int, instructions: list[int]):
    self.__registers = [a, b, c, 0]
    self.__instructions = instructions
    self.__out = []
    self.__counter = 0

  @property
  def a(self) -> int:
    return self.__registers[0]
  @a.setter
  def a(self, value: int):
    self.__registers[0] = value

  @property
  def b(self) -> int:
    return self.__registers[1]
  @b.setter
  def b(self, value: int):
    self.__registers[1] = value

  @property
  def c(self) -> int:
    return self.__registers[2]
  @c.setter
  def c(self, value: int):
    self.__registers[2] = value

  @property
  def p(self) -> int:
    return self.__registers[3]
  @p.setter
  def p(self, value: int):
    self.__registers[3] = value

  @property
  def instructions(self) -> int:
    return self.__instructions

  @property
  def out(self) -> list[int]:
    return self.__out
  
  @property
  def cycle_counter(self) -> int:
    return self.__counter

  def cycle(self) -> bool:
    if self.p >= len(self.instructions):
      return False
    self.__counter += 1

    instruction = self.instructions[self.p]
    operand = self.instructions[self.p + 1]
    self.p += 2

    if operand < 4:
      combo = operand
      combos = operand
    elif operand < 7:
      combo = self.__registers[operand - 4]
    
    match instruction:
      case 0: # adv
        self.a >>= combo
      case 1: # bxl
        self.b ^= operand
      case 2: # bst
        self.b = combo & 7
      case 3: # jnz
        if self.a != 0:
          self.p = operand
      case 4: # bxc
        self.b ^= self.c
      case 5: # out
        self.out.append(combo & 7)
      case 6: # bdv
        self.b = self.a >> combo
      case 7: # cdv
        self.c = self.a >> combo

    return True

  def run(self) -> list[int]:
    while self.cycle():
      pass
    return self.out

  def step(self) -> int | None:
    while self.p < len(self.instructions) and self.instructions[self.p] != 5:
      self.cycle()
    if self.cycle():
      return self.out[-1]
    return None

class ReverseCpu:
  def __init__(self, instructions: list[int], target: list[int]):
    self.__instructions = instructions
    self.__target = target

  def __recurse(self, step: int = 1, a: int = 0) -> int | None:
    if step > len(self.__target):
      return a
    
    target = self.__target[-step:]
    for b in range(8):
      candidate = (a << 3) | b
      cpu = Cpu(candidate, 0, 0, self.__instructions)
      out = cpu.run()

      if out == target:
        value = self.__recurse(step + 1, candidate)
        if value is not None:
          return value
    return None

  def find(self) -> int | None:
    for init in range(1):
      a = self.__recurse(a = init)
      if a is not None:
        return a
    return None




@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  a = int(re.match(r"^Register A: (\d+)", input.readline())[1])
  b = int(re.match(r"^Register B: (\d+)", input.readline())[1])
  c = int(re.match(r"^Register C: (\d+)", input.readline())[1])
  input.readline()

  instructions = [int(i) for i in re.match(r"^Program: (\d(?:,\d)+)", input.readline())[1].split(',')]
  reverse = ReverseCpu(instructions, instructions)
  a = reverse.find()
  print(a)

if __name__ == '__main__':
  part_b()
