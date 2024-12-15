#! /usr/bin/env python3

import re
from collections import defaultdict
from dataclasses import dataclass
from typing import Tuple
import numpy as np

import click

@dataclass
class Robot:
  position: np.array
  velocity: np.array
  shape: np.array

  def move(self, steps: int = 1):
    self.position = (self.position + steps * self.velocity) % self.shape

  def quadrant(self) -> int:
    quad = 0

    for dim in range(2):
      if self.position[dim] < self.shape[dim] // 2:
        quad += 0 * 3**dim
      if self.position[dim] == self.shape[dim] // 2:
        quad += 1 * 3**dim
      if self.position[dim] > self.shape[dim] // 2:
        quad += 2 * 3**dim
    
    return quad
  
  def __str__(self) -> str:
    return f"p={self.position[0]},{self.position[1]} v={self.velocity[0]},{self.velocity[1]}"

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  m = re.match(r"w=(\d+) h=(\d+)", input.readline())
  shape = np.array([int(m[1]), int(m[2])])

  robots = []

  for line in input:
    m = re.match(r"p=(-?\d+),(-?\d+) v=(-?\d+),(-?\d+)", line)
    robot = Robot(np.array([int(m[1]), int(m[2])]), np.array([int(m[3]), int(m[4])]), shape)
    robots.append(robot)

  for i in range(10000):
    mx = 0
    my = 0
    for robot in robots:
      robot.move()
      mx += robot.position[0]
      my += robot.position[1]
    mx /= len(robots)
    my /= len(robots)

    sx = 0
    sy = 0
    for robot in robots:
      sx += (mx - robot.position[0])**2
      sy += (my - robot.position[1])**2
    s2 = sx + sy
    s2 /= len(robots)

    if s2 < 800:
      print(f"{i}: {s2}")



if __name__ == '__main__':
  part_b()
