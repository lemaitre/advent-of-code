#! /usr/bin/env python3

from operator import and_, or_, xor
import click

@click.command()
@click.argument('input', type=click.File('r'))
def part_a(input: click.File):
  ready = {}
  pending = {}
  output = set()

  for line in input:
    if line == '\n':
      break
    wire, value = line[:-1].split(': ')
    ready[wire] = value == '1'
  
  for line in input:
    gate, out = line[:-1].split(' -> ')
    left, op, right = gate.split()
    if op == 'AND':
      op = and_
    elif op == 'OR':
      op = or_
    elif op == 'XOR':
      op = xor
    
    pending[out] = (left, right, op)
    if out[0] == 'z':
      output.add(out)
  
  def get_value(wire: str) -> bool:
    if (value := ready.get(wire)) is not None:
      return value
    left, right, op = pending.pop(wire)
    left = get_value(left)
    right = get_value(right)
    value = op(left, right)
    ready[wire] = value
    return value
  
  n = 0
  for p, wire in enumerate(sorted(output)):
    n |= int(get_value(wire)) << p
  
  click.echo(n)

if __name__ == '__main__':
  part_a()
