#! /usr/bin/env python3

from typing import Optional
from functools import cache
import click

class Circuit:
  def __init__(self, gates: dict[str, tuple[str, str, str]]):
    self.gates = gates
  
  def find_outputs(self, wires: set[str], permutation: dict[str, str]) -> tuple[Optional[str], Optional[str]]:
    ready = {}
    pending = {}
    output = set()
    index = None

    for wire in wires:
      left, right, op = self.gates[permutation.get(wire, wire)]

      for input in (left, right):
        if input[0] in 'xy':
          index = int(input[1:])
          ready[input] = input[0]
      pending[wire] = left, right, op

    def get_wire_name(wire: str) -> Optional[str]:
      if (name := ready.get(wire)) is not None:
        return name
      if wire not in wires:
        ready[wire] = 'pc'
        return 'pc'
      
      if wire not in pending:
        ready[wire] = None
        return None
      left, right, op = pending.pop(wire)
      left = get_wire_name(left)
      right = get_wire_name(right)

      if left is None or right is None:
        ready[wire] = None
        return None

      left, right = min(left, right), max(left, right)

      if left == 'x' and right == 'y':
        if op == 'AND':
          if index == 0:
            ready[wire] = 'c'
          else:
            ready[wire] = 'hc'
        elif op == 'XOR':
          if index == 0:
            ready[wire] = 'z'
          else:
            ready[wire] = 'h'
      elif left == 'h' and right == 'pc' and op == 'AND':
        ready[wire] = 'k'
      elif left == 'hc' and right == 'k' and op == 'OR':
        ready[wire] = 'c'
      elif left == 'h' and right == 'pc' and op == 'XOR':
        ready[wire] = 'z'

      if wire not in ready:
        ready[wire] = None
      return ready[wire]
    
    out = None
    carry = None
    for wire in wires:
      name = get_wire_name(wire)
      if name is None:
        return None, None
      if name == 'z':
        out = wire
      if name == 'c':
        carry = wire
    
    return out, carry

  
  def find_permutation(self, wires: set[str], expected_carry: str) -> Optional[tuple[str, str]]:
    for out1 in wires:
      for out2 in wires:
        permutation = {}
        permutation[out1] = out2
        permutation[out2] = out1
        output, carry = self.find_outputs(wires, permutation)
        if output is not None and output[0] == 'z' and carry == expected_carry:
          return tuple(sorted((out1, out2)))
    return None

@click.command()
@click.argument('input', type=click.File('r'))
def part_b(input: click.File):
  inputs = set()
  outputs = set()
  gates = {}

  for line in input:
    if line == '\n':
      break
  
  for line in input:
    gate, out = line[:-1].split(' -> ')
    left, op, right = gate.split()
    if left > right:
      left, right = right, left
    gates[out] = (left, right, op)

    inputs.add(left)
    inputs.add(right)
    outputs.add(out)
  
  circuit = Circuit(gates)
  
  ranks = {}
  
  @cache
  def rank(wire: str) -> int:
    if wire[0] in 'xy':
      r = int(wire[1:])
    else:
      left, right, _ = gates[wire]
      r = max(rank(left), rank(right))
    return r
  
  for wire in outputs:
    r = rank(wire)
    ranks.setdefault(r, set()).add(wire)
  
  last = len(outputs - inputs) - 1

  expected_carry = f"z{last}"
  permutations = []
  for r in reversed(range(1, last)):
    wires = ranks[r]
    a, b = circuit.find_permutation(wires, expected_carry)
    if a != b:
      permutations.extend((a, b))
    for wire in wires:
      left, right, _ = circuit.gates[wire]
      for input in (left, right):
        if input not in wires and input[0] not in 'xy':
          expected_carry = input
  
  click.echo(",".join(sorted(permutations)))

if __name__ == '__main__':
  part_b()
