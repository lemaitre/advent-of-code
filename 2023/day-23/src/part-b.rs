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
    solve(content).expect("Could not solve part B")
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
                next[n as usize].push((id, l));

                break;
            } else if (i, j) == end {
                next[id as usize].push((0, l));
                break;
            };
        }
    }

    let length = recurse(&next, 1, 0, 2);
    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{}", length);
    Ok(())
}

fn recurse(next: &[Vec<(u8, u32)>], id: u8, length: u32, seen: u64) -> u32 {
    if id == 0 {
        return length;
    }

    let mut max = 0_u32;
    for (n, l) in next[id as usize].iter().copied() {
        let n_mask = 1_u64 << n;
        if (seen & n_mask) != 0 {
            continue;
        }

        let length = recurse(next, n, length + l, seen | n_mask);
        max = max.max(length);
    }

    max
}
