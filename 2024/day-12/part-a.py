#! /usr/bin/env python3

from dataclasses import dataclass

import click

@dataclass
class Parcel:
  idx: int
  plant: str
  area: int
  perimeter: int

  def price(self) -> int:
    return self.area * self.perimeter

class Parcels:
  def __init__(self):
    self.uf = []

  def __getitem__(self, idx: int | Parcel) -> Parcel:
    if isinstance(idx, Parcel):
      idx = idx.idx
    return self.uf[idx]

  def add(self, plant: str) -> Parcel:
    parcel = Parcel(len(self.uf), plant, 1, 4)
    self.uf.append(parcel)
    return parcel

  def root(self, parcel: int | Parcel) -> Parcel:
    parcel = self[parcel]

    while True:
      parent = self.uf[parcel.idx]
      if parent.idx == parcel.idx:
        return parent
      parcel = parent

  def merge_roots(self, a: Parcel, b: Parcel) -> Parcel:
    if b.idx < a.idx:
      a, b = b, a

    assert(self.uf[a.idx].idx == a.idx)
    assert(self.uf[b.idx].idx == b.idx)

    if a.idx != b.idx:
      a.area += b.area
      a.perimeter += b.perimeter
      b.area = 0
      b.perimeter = 0
    
    b.idx = a.idx

    return a

  def close(self):
    for parcel in self.uf:
      root = self.root(parcel)
      parcel.idx = root.idx

  def __iter__(self):
    for idx, parcel in enumerate(self.uf):
      if idx == parcel.idx:
        yield parcel

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  parcels = Parcels()

  above: list[Parcel] | None = None

  for i, line in enumerate(input):
    left: Parcel | None = None
    current: list[Parcel] = []
    for j, c in enumerate(line.strip()):
      neighborhood = []

      if left is not None:
        if left.plant == c:
          neighborhood.append(left)
      if above is not None:
        up = above[j]
        if up.plant == c:
          neighborhood.append(parcels.root(up))
      
      if len(neighborhood) == 0:
        c = parcels.add(c)
      elif len(neighborhood) == 1:
        c = neighborhood[0]
        c.area += 1
        c.perimeter += 2
      else:
        a, b = neighborhood
        c = parcels.merge_roots(a, b)
        c.area += 1
      
      current.append(c)
      left = c
    above = current

  parcels.close()

  s = sum(parcel.price() for parcel in parcels)
  click.echo(s)

if __name__ == '__main__':
  part_a()
