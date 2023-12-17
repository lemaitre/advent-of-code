use std::time::Instant;

use anyhow::{bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Grid, UnionFind,
};

use crate::pipe::{Direction, Pipe};

mod pipe;

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

    let mut pipes = Grid::new();
    let mut start = None;
    for (i, line) in input.lines().enumerate() {
        pipes.try_add_row(line.as_slice().iter().map(Pipe::from_char))?;
        for (j, chr) in line.as_slice().iter().enumerate() {
            match (chr, start) {
                (AsciiChar::S, None) => start = Some((i as isize, j as isize)),
                (AsciiChar::S, Some((i2, j2))) => {
                    bail!("Found extra starting point at ({i2}, {j2}), previous was ({i}, {j})")
                }
                _ => (),
            }
        }
    }

    let Some(start) = start else {
        bail!("No starting point found");
    };

    let mut in_loop = Grid::with_size(pipes.rows(), pipes.cols(), false);

    for mut dir in [
        Direction::North,
        Direction::South,
        Direction::East,
        Direction::West,
    ] {
        let mut pos = start;
        loop {
            let (i, j) = dir.advance_from(pos);
            let Some(pipe) = pipes.get(i, j) else {
                break;
            };
            let Some(d) = pipe.enter(dir.opposite()) else {
                break;
            };

            let Some(cell) = in_loop.get_mut(i, j) else {
                bail!("Could not access {i}, {j}");
            };

            if *cell {
                break;
            }
            *cell = true;
            pos = (i, j);
            dir = d;
        }
    }

    let mut extended = Grid::with_size(pipes.rows() * 2 + 1, pipes.cols() * 2 + 1, false);

    for i in 0..pipes.rows() as isize {
        for j in 0..pipes.cols() as isize {
            if *in_loop.get(i, j).unwrap_or(&false) {
                let pipe = pipes.get(i, j).unwrap_or(&Pipe::Ground);
                let i = 2 * i + 1;
                let j = 2 * j + 1;

                *extended.get_mut(i, j).unwrap() = true;

                match pipe {
                    Pipe::NorthSouth => {
                        *extended.get_mut(i - 1, j).unwrap() = true;
                        *extended.get_mut(i + 1, j).unwrap() = true;
                    }
                    Pipe::EastWest => {
                        *extended.get_mut(i, j - 1).unwrap() = true;
                        *extended.get_mut(i, j + 1).unwrap() = true;
                    }
                    Pipe::NorthEast => {
                        *extended.get_mut(i - 1, j).unwrap() = true;
                        *extended.get_mut(i, j + 1).unwrap() = true;
                    }
                    Pipe::NorthWest => {
                        *extended.get_mut(i - 1, j).unwrap() = true;
                        *extended.get_mut(i, j - 1).unwrap() = true;
                    }
                    Pipe::SouthEast => {
                        *extended.get_mut(i + 1, j).unwrap() = true;
                        *extended.get_mut(i, j + 1).unwrap() = true;
                    }
                    Pipe::SouthWest => {
                        *extended.get_mut(i + 1, j).unwrap() = true;
                        *extended.get_mut(i, j - 1).unwrap() = true;
                    }
                    _ => (),
                }
            }
        }
    }

    let mut union_find = UnionFind::<u32, u32>::with_capacity(extended.rows() * extended.cols());
    union_find.push(0).unwrap();

    let mut labeled = Grid::with_size(extended.rows(), extended.cols(), 0_u32);

    for i in 0..extended.rows() as isize {
        let mut left = false;
        let mut left_l = 0;
        for j in 0..extended.cols() as isize {
            let center = *extended.get(i, j).unwrap_or(&false);

            if !center {
                let up = *extended.get(i - 1, j).unwrap_or(&false);
                #[allow(unused_assignments)]
                let mut center_l = 0;

                let weight = if i & 1 == 1 && j & 1 == 1 { 1 } else { 0 };

                match (left, up) {
                    (true, true) => {
                        center_l = union_find.push(weight).unwrap();
                    }
                    (true, false) => {
                        center_l = *labeled.get(i - 1, j).unwrap_or(&0);
                        *union_find.features_mut(center_l) += weight;
                    }
                    (false, true) => {
                        center_l = left_l;
                        *union_find.features_mut(center_l) += weight;
                    }
                    (false, false) => {
                        center_l = union_find.merge(left_l, *labeled.get(i - 1, j).unwrap_or(&0));
                        *union_find.features_mut(center_l) += weight;
                    }
                }

                *labeled.get_mut(i, j).unwrap() = center_l;

                left_l = center_l;
            }

            left = center;
        }

        if !left {
            union_find.merge(left_l, 0);
        }
    }

    *union_find.features_mut(0) = 0;

    let mut surface = 0;
    for (_, s) in union_find.inner() {
        surface += s;
    }

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{surface}");
    Ok(())
}
