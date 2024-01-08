use std::time::Instant;

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiStr},
    Direction, Grid,
};

mod tile;
pub use tile::Tile;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

pub struct Stack(Vec<(isize, isize, Direction)>);

impl Stack {
    pub fn new() -> Self {
        Self(vec![(0, -1, Direction::East)])
    }

    pub fn push(&mut self, i: isize, j: isize, dir: Direction) {
        self.0.push((i, j, dir));
    }
    pub fn push_if(&mut self, b: &mut bool, i: isize, j: isize, dir: Direction) {
        if !*b {
            *b = true;
            self.push(i, j, dir);
        }
    }
    pub fn pop(&mut self) -> Option<(isize, isize, Direction)> {
        self.0.pop()
    }
}

impl Default for Stack {
    fn default() -> Self {
        Self::new()
    }
}

type BitSet = bitvec::array::BitArray<[u64; 8]>;

fn bit_set(i: usize) -> BitSet {
    let mut set = BitSet::default();
    set.set(i, true);
    set
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut grid = Grid::new();
    for line in input.lines() {
        grid.try_add_row(line.into_iter().map(|&chr| Tile::<BitSet>::from_char(chr)))?;
    }
    let mut stack = Vec::new();

    let mut t = 0;
    for i in 0..grid.rows() as isize {
        stack.push((i, 0, Direction::East, bit_set(t)));
        stack.push((i, grid.cols() as isize - 1, Direction::West, bit_set(t + 1)));
        t += 2;
    }
    for j in 0..grid.cols() as isize {
        stack.push((0, j, Direction::South, bit_set(t)));
        stack.push((
            grid.rows() as isize - 1,
            0,
            Direction::North,
            bit_set(t + 1),
        ));
        t += 2;
    }

    while let Some((i, j, dir, bits)) = stack.pop() {
        let Some(tile) = grid.get_mut(i, j) else {
            continue;
        };

        let light = tile.get_from(dir.reflect());

        if (*light & bits) != bits {
            use Direction::*;
            use Tile::*;

            *light |= bits;

            let light = *light;

            match (dir, tile) {
                (_, Empty { .. })
                | (East | West, HorizontalSplitter { .. })
                | (North | South, VerticalSplitter { .. }) => {
                    let (i, j) = dir.step(i, j);
                    stack.push((i, j, dir, light));
                }
                (_, ForwardMirror { .. }) => {
                    let dir = dir.reflect_diagonal_forward();
                    let (i, j) = dir.step(i, j);
                    stack.push((i, j, dir, light));
                }
                (_, BackwardMirror { .. }) => {
                    let dir = dir.reflect_diagonal_backward();
                    let (i, j) = dir.step(i, j);
                    stack.push((i, j, dir, light));
                }
                (North | South, HorizontalSplitter { horizontal, .. }) => {
                    *horizontal |= light;
                    let (i1, j1) = East.step(i, j);
                    let (i2, j2) = West.step(i, j);
                    stack.push((i1, j1, East, *horizontal));
                    stack.push((i2, j2, West, *horizontal));
                }
                (East | West, VerticalSplitter { vertical, .. }) => {
                    *vertical |= light;
                    let (i1, j1) = North.step(i, j);
                    let (i2, j2) = South.step(i, j);
                    stack.push((i1, j1, North, *vertical));
                    stack.push((i2, j2, South, *vertical));
                }
            }
        }
    }

    let mut sizes = Vec::new();
    sizes.resize(2 * (grid.cols() + grid.rows()), 0_u32);

    for row in grid.iter() {
        for tile in row.iter() {
            let bits = tile.is_energized();

            for i in bits.iter_ones() {
                sizes[i] += 1;
            }
        }
    }

    let elapsed = timer.elapsed();
    println!(
        "Part B ({elapsed:?}):\n{}",
        sizes.iter().max().ok_or(anyhow!("no size"))?
    );
    Ok(())
}
