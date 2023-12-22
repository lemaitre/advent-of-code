use std::{
    cmp::Reverse,
    collections::{BinaryHeap, HashMap},
    time::Instant,
};

use anyhow::{anyhow, bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    SplitExact,
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
    idx: HashMap<&'a AsciiStr, u16>,
    lefts: Vec<u16>,
    rights: Vec<u16>,
}

impl<'a> Map<'a> {
    fn with_capacity(capacity: usize) -> Self {
        Self {
            idx: HashMap::with_capacity(capacity),
            lefts: Vec::with_capacity(capacity),
            rights: Vec::with_capacity(capacity),
        }
    }

    fn allocate_node(&mut self, node: &'a AsciiStr) -> u16 {
        let i = self.idx.len() as u16;
        match self.idx.entry(node) {
            std::collections::hash_map::Entry::Occupied(entry) => *entry.get(),
            std::collections::hash_map::Entry::Vacant(entry) => *entry.insert(i),
        }
    }

    fn add_node(&mut self, node: &'a AsciiStr, left: &'a AsciiStr, right: &'a AsciiStr) -> u16 {
        let node = self.allocate_node(node);
        let left = self.allocate_node(left);
        let right = self.allocate_node(right);
        self.lefts
            .resize(self.lefts.len().max(node as usize + 1), 0);
        self.rights
            .resize(self.rights.len().max(node as usize + 1), 0);

        self.lefts[node as usize] = left;
        self.rights[node as usize] = right;

        node
    }

    #[inline]
    fn left(&self, node: u16) -> u16 {
        self.lefts[node as usize]
    }
    #[inline]
    fn right(&self, node: u16) -> u16 {
        self.rights[node as usize]
    }
    fn size(&self) -> u16 {
        self.idx.len() as u16
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Cursor {
    time: u64,
    dir: u16,
    node: u16,
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut lines = input.lines();

    let directions = lines.next().ok_or(anyhow!("no directions given"))?;
    lines.next().ok_or(anyhow!("missing empty line"))?;
    let mut map = Map::with_capacity(800);

    // allocate terminal nodes
    for line in lines {
        let [node, _] = line.split_exact(AsciiChar::Equal)?.map(AsciiStr::trim);

        if node[2] == AsciiChar::Z {
            map.allocate_node(node);
        }
    }

    let end = map.size();
    let n = directions.len() as u16;

    let mut currents = BinaryHeap::<Reverse<Cursor>>::with_capacity(end as usize);

    for line in input.lines().skip(2) {
        let [node, edges] = line.split_exact(AsciiChar::Equal)?.map(AsciiStr::trim);
        let [left, right] = edges.split_exact(AsciiChar::Comma)?.map(AsciiStr::trim);
        debug_assert!(left[0] == AsciiChar::ParenOpen);
        debug_assert!(right[right.len() - 1] == AsciiChar::ParenClose);
        let left = &left[1..];
        let right = &right[..right.len() - 1];

        let node_idx = map.add_node(node, left, right);

        if node[2] == AsciiChar::A {
            currents.push(Reverse(Cursor {
                time: 0,
                dir: 0,
                node: node_idx,
            }));
        }
    }

    let mut cache = HashMap::<(u16, u16), Cursor>::with_capacity(currents.len());

    let combined: u64;
    loop {
        let mut min = u64::MAX;
        let mut max = u64::MIN;

        for cursor in currents.iter() {
            min = min.min(cursor.0.time);
            max = max.max(cursor.0.time);
        }

        if min == max && min > 0 {
            combined = min;
            break;
        }

        let Some(mut current) = currents.peek_mut() else {
            bail!("No cursor");
        };
        let current = &mut current.0;

        match cache.entry((current.node, current.dir)) {
            std::collections::hash_map::Entry::Occupied(entry) => {
                let time = current.time;
                *current = *entry.get();
                current.time += time;
            }
            std::collections::hash_map::Entry::Vacant(entry) => {
                let mut cursor = *current;
                loop {
                    if directions[cursor.dir as usize] == AsciiChar::L {
                        cursor.node = map.left(cursor.node);
                    } else {
                        cursor.node = map.right(cursor.node);
                    }
                    cursor.time += 1;
                    cursor.dir += 1;
                    if cursor.dir == n {
                        cursor.dir = 0;
                    }
                    if cursor.node < end {
                        break;
                    }
                }

                let diff = cursor.time - current.time;
                *current = cursor;
                cursor.time = diff;

                entry.insert(cursor);
            }
        }
    }

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{combined}");
    Ok(())
}
