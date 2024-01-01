use std::collections::BinaryHeap;

use anyhow::{anyhow, Result};

use aoc_lib::{ascii::AsciiStr, CharExt, Direction, Factor, Grid};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Node {
    pub i: isize,
    pub j: isize,
    pub d: Direction,
    pub cost: u32,
}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        other.cost.partial_cmp(&self.cost)
    }
}
impl Ord for Node {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        other.cost.cmp(&self.cost)
    }
}

pub struct Solver {
    pub map: Grid<u32>,
    pub heatloss: Grid<[u32; 4]>,
    pub heap: BinaryHeap<Node>,
}

impl Solver {
    pub fn from_input(input: &AsciiStr) -> Result<Self> {
        let mut map = Grid::new();
        for line in input.lines() {
            map.try_add_row(line.into_iter().map(|chr| chr.to_int()))?;
        }

        let heatloss = map.map(|_| [u32::MAX; 4]);
        let heap = BinaryHeap::new();

        Ok(Self {
            map,
            heatloss,
            heap,
        })
    }
    pub fn explore_from<const FORCE: usize, const MAX: usize>(
        &mut self,
        mut i: isize,
        mut j: isize,
        dir: Direction,
        mut cost: u32,
    ) {
        for _ in 0..FORCE {
            (i, j) = dir.step(i, j);

            let Some(&cell_loss) = self.map.get(i, j) else {
                return;
            };

            cost += cell_loss;
        }

        for _ in FORCE..MAX {
            (i, j) = dir.step(i, j);

            let Some((&cell_loss, loss)) =
                (self.map.get(i, j), self.heatloss.get_mut(i, j)).factor()
            else {
                return;
            };
            let loss = &mut loss[u8::from(dir) as usize];
            cost += cell_loss;

            if cost < *loss {
                *loss = cost;

                self.heap.push(Node { i, j, d: dir, cost });
            }
        }
    }

    pub fn solve<const FORCE: usize, const MAX: usize>(&mut self) -> Result<u32> {
        for dir in [Direction::East, Direction::South] {
            self.explore_from::<FORCE, MAX>(0, 0, dir, 0);
        }

        while let Some(Node { i, j, d, cost }) = self.heap.pop() {
            if i == self.map.rows() as isize - 1 && j == self.map.cols() as isize - 1 {
                return Ok(cost);
            }

            for dir in [d.rotate_left(), d.rotate_right()] {
                self.explore_from::<FORCE, MAX>(i, j, dir, cost);
            }
        }

        Err(anyhow!("Could not reach bottom left corner"))
    }
}
