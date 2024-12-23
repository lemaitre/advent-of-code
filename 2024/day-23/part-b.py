#! /usr/bin/env python3

from typing import Iterable, Optional, Self
from itertools import chain
import click

class GraphNode:
  def __init__(self, name: str, neighbors: Optional[set[Self]] = None):
    if neighbors is None:
      neighbors = {self}
    self.name = name
    self.neighbors = neighbors
  
  def __repr__(self) -> str:
    return f"GraphNode({self.name!r}, {[n.name for n in self.neighbors]!r})"
  
  def __str__(self) -> str:
    return self.name


class Graph:
  def __init__(self):
    self.nodes = {}
  
  def node(self, n: str | GraphNode) -> GraphNode:
    if isinstance(n, GraphNode):
      return n
    n = str(n)
    if n not in self.nodes:
      self.nodes[n] = GraphNode(n)
    return self.nodes[n]
    
  def add_edge(self, a: str | GraphNode, b: str | GraphNode):
    a = self.node(a)
    b = self.node(b)

    if a is not b:
      a.neighbors.add(b)
      b.neighbors.add(a)
  
  def __iter__(self) -> Iterable[GraphNode]:
    return iter(self.nodes.values())
  
  def __len__(self) -> int:
    return len(self.nodes)


@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  computers = Graph()
  for line in input:
    a, b = line[:-1].split('-')
    computers.add_edge(a, b)
  
  candidates = set()
  for node1 in computers:
    for node2 in computers:
      if id(node1) >= id(node2):
        continue
      if node1 not in node2.neighbors or node2 not in node1.neighbors:
        continue
      candidate = frozenset(node1.neighbors & node2.neighbors)
      if len(candidate) > 2:
        candidates.add(candidate)
  
  for candidate in sorted(candidates, key = lambda s: -len(s)):
    it = iter(candidate)
    neighborhood = next(it).neighbors
    for neighbor in it:
      neighborhood.intersection_update(neighbor.neighbors)
    if candidate == neighborhood:
      print(",".join(sorted(map(str, candidate))))
      break

if __name__ == '__main__':
  part_b()
