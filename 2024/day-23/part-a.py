#! /usr/bin/env python3

from typing import Iterable, Optional, Self
import click

class GraphNode:
  def __init__(self, name: str, neighbors: Optional[set[Self]] = None):
    if neighbors is None:
      neighbors = set()
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


@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  computers = Graph()
  for line in input:
    a, b = line[:-1].split('-')
    computers.add_edge(a, b)
  
  
  triplets = set()
  for a in computers:
    for b in a.neighbors:
      for c in b.neighbors.intersection(a.neighbors):
        triplets.add(tuple(sorted((a, b, c), key = lambda n: n.name)))
  
  s = 0
  for a, b, c in triplets:
    if a.name[0] == 't' or b.name[0] == 't' or c.name[0] == 't':
      s += 1
  
  click.echo(s)

if __name__ == '__main__':
  part_a()
