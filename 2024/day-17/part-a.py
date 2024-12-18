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



@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  a = int(re.match(r"^Register A: (\d+)", input.readline())[1])
  b = int(re.match(r"^Register B: (\d+)", input.readline())[1])
  c = int(re.match(r"^Register C: (\d+)", input.readline())[1])
  input.readline()

  instructions = [int(i) for i in re.match(r"^Program: (\d(?:,\d)+)", input.readline())[1].split(',')]

  cpu = Cpu(a, b, c, instructions)
  out = cpu.run()

  a, b, c = None, None, None
  expected = None

  for line in input:
    if m := re.match(r"^Register A: (\d+)", line):
      a = int(m[1])
    if m := re.match(r"^Register B: (\d+)", line):
      b = int(m[1])
    if m := re.match(r"^Register C: (\d+)", line):
      c = int(m[1])
    if m := re.match(r"^Output: (\d(?:,\d)+)", line):
      expected = [int(i) for i in m[1].split(',')]

  print(f"a = {cpu.a}\tb = {cpu.b}\tc = {cpu.c}\tp = {cpu.p}\tcounter = {cpu.cycle_counter}\nout = {out}")
  assert(a is None or a == cpu.a)
  assert(b is None or b == cpu.b)
  assert(c is None or c == cpu.c)
  assert(expected is None or expected == cpu.out)

  print(",".join(str(o) for o in out))

if __name__ == '__main__':
  part_a()
