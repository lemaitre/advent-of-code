use std::time::Instant;

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Direction, IntegerMap,
};
use ndarray::s;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let width = input.lines().next().ok_or(anyhow!("Empty input"))?.len();
    let height = input.len() / (width + 1);

    let grid = ndarray::aview1(input.as_slice()).into_shape((height, width + 1))?;
    let grid = grid.slice(s![.., ..-1]);

    let mut nodes = IntegerMap::<(usize, usize), u8>::new();
    let end = (grid.nrows() - 1, grid.ncols() - 2);
    nodes.id(end);
    nodes.id((0, 1));
    let mut next: Vec<Vec<(u8, u32)>> = vec![vec![], vec![]];
    let mut stack = vec![(1_u8, Direction::South)];

    while let Some((id, mut d)) = stack.pop() {
        let (mut i, mut j) = nodes.value(id);
        (i, j) = d.stepu(i, j);
        let mut l = 1;
        loop {
            let mut cell = AsciiChar::Dot;
            for dir in [d, d.rotate_left(), d.rotate_right()] {
                let (ni, nj) = dir.stepu(i, j);
                cell = grid[(ni, nj)];

                if cell != AsciiChar::Hash {
                    (i, j, d) = (ni, nj, dir);
                    break;
                }
            }
            l += 1;

            if cell != AsciiChar::Dot {
                l += 1;
                (i, j) = d.stepu(i, j);

                let (n, success) = nodes.try_insert((i, j));
                next[id as usize].push((n, l));

                if success {
                    next.resize(next.len().max(n as usize + 1), Default::default());
                    for d in [Direction::South, Direction::East] {
                        if grid[d.stepu(i, j)] != AsciiChar::Hash {
                            stack.push((n, d));
                        }
                    }
                }

                break;
            } else if (i, j) == end {
                next[id as usize].push((0, l));
                break;
            };
        }
    }

    let mut distances = vec![0_u32; next.len()];
    let mut stable = false;
    while !stable {
        stable = true;
        for (id, neighbors) in next.iter().enumerate().skip(1) {
            let d = distances[id];
            for (n, l) in neighbors.iter().copied() {
                let neighbor = &mut distances[n as usize];
                if *neighbor < d + l {
                    *neighbor = d + l;
                    stable = false;
                }
            }
        }
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{}", distances[0]);
    Ok(())
}
