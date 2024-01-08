use std::time::Instant;

use anyhow::Result;
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
    solve(content).expect("Could not solve part A")
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

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut grid = Grid::new();
    for line in input.lines() {
        grid.try_add_row(line.into_iter().map(|&chr| Tile::<bool>::from_char(chr)))?;
    }
    let mut stack = Vec::new();
    stack.push((0_isize, 0_isize, Direction::East));

    while let Some((i, j, dir)) = stack.pop() {
        let Some(tile) = grid.get_mut(i, j) else {
            continue;
        };

        let light = tile.get_from(dir.reflect());
        if !*light {
            *light = true;

            use Direction::*;
            use Tile::*;

            match (dir, tile) {
                (_, Empty { .. })
                | (East | West, HorizontalSplitter { .. })
                | (North | South, VerticalSplitter { .. }) => {
                    let (i, j) = dir.step(i, j);
                    stack.push((i, j, dir));
                }
                (_, ForwardMirror { .. }) => {
                    let dir = dir.reflect_diagonal_forward();
                    let (i, j) = dir.step(i, j);
                    stack.push((i, j, dir));
                }
                (_, BackwardMirror { .. }) => {
                    let dir = dir.reflect_diagonal_backward();
                    let (i, j) = dir.step(i, j);
                    stack.push((i, j, dir));
                }
                (North | South, HorizontalSplitter { horizontal, .. }) => {
                    *horizontal = true;
                    let (i1, j1) = East.step(i, j);
                    let (i2, j2) = West.step(i, j);
                    stack.push((i1, j1, East));
                    stack.push((i2, j2, West));
                }
                (East | West, VerticalSplitter { vertical, .. }) => {
                    *vertical = true;
                    let (i1, j1) = North.step(i, j);
                    let (i2, j2) = South.step(i, j);
                    stack.push((i1, j1, North));
                    stack.push((i2, j2, South));
                }
            }
        }
    }
    let s = grid
        .iter()
        .map(|row| {
            row.iter()
                .map(|tile| tile.is_energized() as u32)
                .sum::<u32>()
        })
        .sum::<u32>();

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{s}");
    Ok(())
}
