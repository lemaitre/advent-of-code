#! /usr/bin/env python3

from collections import deque
from itertools import islice

import click
import numpy as np

# https://largo.lip6.fr/~lacas/Publications/TPDS22_maxtree-gpu.pdf
class MaxTree:
  def __init__(self, grid):
    self.width = grid.shape[1]
    self.height = grid.shape[0]
    self.X = grid.reshape(-1)
    self.L = np.zeros(self.X.shape, int)

  def find_pseudo_root(self, v: int, l: int) -> int:
    r = self.L[l]
    while self.X[r] >= v:
      l = r
      r = self.L[r]
    return l
  
  def merge(self, root: int, root_val: int, l1: int, l2: int) -> int:
    v1 = self.X[l1]
    v2 = self.X[l2]
    if v1 > v2:
      l1, l2 = l2, l1
      v1, v2 = v2, v1
    
    if v1 == root_val:
      return root
    
    l1 = self.find_pseudo_root(v1, l1)
    l2 = self.find_pseudo_root(v2, l2)
    while True:
      r = l2
      while self.X[self.L[r]] > v1:
        r = self.L[r]
      l2 = r
      v2 = self.X[l2]

      if l1 == l2:
        return l1
      if v1 == v2 and l1 > l2:
        l1, l2 = l2, l1
      
      l = self.L[l2]
      self.L[l2] = l1
      v2 = self.X[l]
      if v2 == root_val:
        return root
      l2 = self.find_pseudo_root(v2, l)
      if v1 > v2:
        l1, l2 = l2, l1
        v1, v2 = v2, v1
  
  def __call__(self):
    # i = 0
    self.L[0] = 0
    root = 0
    root_val = self.X[0]

    for l in range(1, self.width):
      v = self.X[l]
      self.L[l] = root
      if v < root_val:
        self.L[root] = l
        self.L[l] = l
        root = l
        root_val = v
      if v > root_val:
        self.merge(root, root_val, l, l-1)
    
    for i in range(1, self.height):
      off = i * self.width

      # j = 0
      j = 0
      l = off + j
      v = self.X[l]
      self.L[l] = root
      if v < root_val:
        self.L[root] = l
        self.L[l] = l
        root = l
        root_val = v
      if v > root_val:
        # up
        self.merge(root, root_val, l, l - self.width)
      
      for j in range(1, self.width):
        l = off + j
        v = self.X[l]
        self.L[l] = root
        if v < root_val:
          self.L[root] = l
          self.L[l] = l
          root = l
          root_val = v
        if v > root_val:
          # up
          self.merge(root, root_val, l, l - self.width)
          # left
          self.merge(root, root_val, l, l - 1)
    
    # intra-value flattening
    for l, a in enumerate(self.L):
      if self.X[self.L[a]] == self.X[a]:
        self.L[l] = self.L[a]

  def common_ancestor(self, l1: int, l2: int) -> int:
    v1 = self.X[l1]
    v2 = self.X[l2]

    while l1 != l2:
      if v1 == v2:
        if l1 < l2:
          l2 = self.L[l2]
          v2 = self.X[l2]
        else:
          l1 = self.L[l1]
          v1 = self.X[l1]
      elif v1 < v2:
        l2 = self.L[l2]
        v2 = self.X[l2]
      elif v1 > v2:
        l1 = self.L[l1]
        v1 = self.X[l1]

    return l1

@click.command()
@click.argument('input', type=click.File('r'))
@click.option('-w', '--width', type=int, default=71)
@click.option('-h', '--height', type=int, default=71)
def part_b(input: click.File, width: int, height: int):
  grid = np.full((height, width), 2**15-1, np.uint16)
  blocks = []
  for t, line in enumerate(input):
    x, y = (int(c) for c in line.split(','))
    blocks.append((x, y))
    grid[y, x] = t

  max_tree = MaxTree(grid)
  max_tree()

  l = max_tree.common_ancestor(0, width * height - 1)
  v = max_tree.X[l]
  x, y = blocks[v]

  print(v)
  print(f"{x},{y}")
  


if __name__ == '__main__':
  part_b()
