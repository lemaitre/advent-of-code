#! /usr/bin/env python3

from typing import Tuple
import re

import click

pair_regex = re.compile(r"^\D*(\d+)\D+(\d+)\D*$")

class System:
  def __init__(self, a: Tuple[int, int], b: Tuple[int, int], t: Tuple[int, int]):
    self.a = a
    self.b = b
    self.t = t

  @staticmethod
  def from_file(file: click.File):
    a = file.readline()
    if not a:
      return None
    b = file.readline()
    t = file.readline()
    file.readline()


    m = pair_regex.match(a)
    a = (int(m[1]), int(m[2]))

    m = pair_regex.match(b)
    b = (int(m[1]), int(m[2]))

    m = pair_regex.match(t)
    t = (int(m[1]), int(m[2]))

    return System(a, b, t)
  
  def solve(self) -> Tuple[int, int] | None:
    den = self.a[0] * self.b[1] - self.a[1] * self.b[0]
    if den == 0:
      return None
    
    x = self.t[0] * self.b[1] - self.t[1] * self.b[0]
    y = self.t[0] * self.a[1] - self.t[1] * self.a[0]

    if x % den != 0 or y % den != 0:
      return None

    return (x // den, y // -den)

  def __str__(self) -> str:
    return f"{self.a}, {self.b} -> {self.t}"

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  s = 0

  while True:
    system = System.from_file(input)
    if system is None:
      break
    solution = system.solve()
    print(f"{system}  => {solution}")

    if solution is not None:
      a, b = solution
      s += a*3 + b
  
  print(s)


if __name__ == '__main__':
  part_a()
