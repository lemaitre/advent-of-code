#! /usr/bin/env python3

from dataclasses import dataclass
from operator import and_, or_, xor
import click

@dataclass
class Wire:
  name: str
  index: int
  label: str

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  ready = {}
  pending = {}
  output = set()

  for line in input:
    if line == '\n':
      break
    wire, _ = line[:-1].split(': ')
    ready[wire] = Wire(wire[0], int(wire[1:]), wire)

  
  for line in input:
    gate, out = line[:-1].split(' -> ')
    left, op, right = gate.split()

    match out:
      case 'z07':
        out = 'vmv'
      case 'vmv':
        out = 'z07'
      case 'z20':
        out = 'kfm'
      case 'kfm':
        out = 'z20'
      case 'z28':
        out = 'hnv'
      case 'hnv':
        out = 'z28'
      case 'hth':
        out = 'tqr'
      case 'tqr':
        out = 'hth'

    pending[out] = (left, right, op)
    if out[0] == 'z':
      output.add(out)
  
  def get_wire(wire: str) -> Wire:
    if (value := ready.get(wire)) is not None:
      return value

    left, right, op = pending.pop(wire)
    left = get_wire(left)
    right = get_wire(right)

    if left.name > right.name:
      left, right = right, left

    if left.name == 'x' and right.name == 'y':
      assert(left.index == right.index)
      if op == 'AND':
        if left.index == 0:
          ready[wire] = Wire('c', left.index, wire)
        else:
          ready[wire] = Wire('hc', left.index, wire)
      elif op == 'XOR':
        if left.index == 0:
          ready[wire] = Wire('z', left.index, wire)
        else:
          ready[wire] = Wire('h', left.index, wire)
    elif left.name == 'c' and right.name == 'h' and op == 'AND':
      assert(left.index + 1 == right.index)
      ready[wire] = Wire('k', right.index, wire)
    elif left.name == 'hc' and right.name == 'k' and op == 'OR':
      assert(left.index == right.index)
      ready[wire] = Wire('c', left.index, wire)
    elif left.name == 'c' and right.name == 'h' and op == 'XOR':
      assert(left.index + 1 == right.index)
      ready[wire] = Wire('z', right.index, wire)



    if wire not in ready:
      print(f"ERROR on wire {wire}")
      ready[wire] = Wire(wire, max(left.index, right.index), wire)
    print(f"{left} {op} {right} -> {ready[wire]}")
    return ready[wire]
  
  # get_wire('z00')
  # get_wire('z01')
  # get_wire('z02')
  # get_wire('z03')

  for p, wire in enumerate(sorted(output)):
    get_wire(wire)

if __name__ == '__main__':
  part_b()
