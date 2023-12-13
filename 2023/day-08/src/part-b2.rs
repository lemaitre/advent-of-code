use std::{collections::HashMap, time::Instant};

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    lcm, SplitExact,
};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

struct Map<'a> {
    lut: HashMap<&'a AsciiStr, u16>,
    lefts: Vec<u16>,
    rights: Vec<u16>,
}

impl<'a> Map<'a> {
    fn with_capacity(capacity: usize) -> Self {
        Self {
            lut: HashMap::with_capacity(capacity),
            lefts: Vec::with_capacity(capacity),
            rights: Vec::with_capacity(capacity),
        }
    }

    fn allocate_node(&mut self, node: &'a AsciiStr) -> u16 {
        let i = self.lut.len() as u16;
        match self.lut.entry(node) {
            std::collections::hash_map::Entry::Occupied(entry) => *entry.get(),
            std::collections::hash_map::Entry::Vacant(entry) => *entry.insert(i),
        }
    }

    fn add_node(&mut self, node: &'a AsciiStr, left: &'a AsciiStr, right: &'a AsciiStr) -> u16 {
        let stop = node[2] == AsciiChar::Z;
        let node = self.allocate_node(node);
        let left = if stop { node } else { self.allocate_node(left) };
        let right = if stop {
            node
        } else {
            self.allocate_node(right)
        };
        self.lefts
            .resize(self.lefts.len().max(node as usize + 1), 0);
        self.rights
            .resize(self.rights.len().max(node as usize + 1), 0);

        self.lefts[node as usize] = left;
        self.rights[node as usize] = right;

        node
    }

    fn left(&self, node: u16) -> Option<u16> {
        let l = self.lefts[node as usize];
        if l == node {
            None
        } else {
            Some(l)
        }
    }
    fn right(&self, node: u16) -> Option<u16> {
        let l = self.rights[node as usize];
        if l == node {
            None
        } else {
            Some(l)
        }
    }
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut lines = input.lines();

    let directions = lines.next().ok_or(anyhow!("no directions given"))?;
    let mut map = Map::with_capacity(800);
    let mut currents = Vec::new();

    for line in lines {
        if line.is_empty() {
            continue;
        }

        let [node, edges] = line.split_exact(AsciiChar::Equal)?.map(AsciiStr::trim);
        let [left, right] = edges.split_exact(AsciiChar::Comma)?.map(AsciiStr::trim);
        debug_assert!(left[0] == AsciiChar::ParenOpen);
        debug_assert!(right[right.len() - 1] == AsciiChar::ParenClose);
        let left = &left[1..];
        let right = &right[..right.len() - 1];

        let node_idx = map.add_node(node, left, right);

        if node[2] == AsciiChar::A {
            currents.push(node_idx);
        }
    }

    let mut combined = 1;

    for current in currents {
        let mut i = 0;
        let mut j = 0;
        let n = directions.len();

        let mut current = Some(current);
        while let Some(idx) = current {
            if directions[j] == AsciiChar::L {
                current = map.left(idx);
            } else {
                current = map.right(idx);
            }
            i += 1;
            j += 1;
            if j == n {
                j = 0;
            }
        }

        combined = lcm(combined, (i - 1) as u64);
    }

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{combined}");
    Ok(())
}
