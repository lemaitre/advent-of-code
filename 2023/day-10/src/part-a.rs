use std::time::Instant;

use anyhow::{bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    CharExt, Factor, Grid,
};

use crate::pipe::{Direction, Pipe};

mod pipe;

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

    let mut distances = Grid::<u32>::with_size(pipes.rows(), pipes.cols(), u32::MAX);

    let candidates = [
        Direction::North,
        Direction::South,
        Direction::East,
        Direction::West,
    ]
    .map(|mut dir| {
        let mut distance = 0;
        let mut pos = start;
        loop {
            let (i, j) = dir.advance_from(pos);
            let Some(pipe) = pipes.get(i, j) else {
                break;
            };
            let Some(d) = pipe.enter(dir.opposite()) else {
                break;
            };

            let Some(cell) = distances.get_mut(i, j) else {
                bail!("Could not access {i}, {j}");
            };

            if *cell <= distance {
                break;
            }
            distance += 1;
            *cell = distance;
            pos = (i, j);
            dir = d;
        }

        Ok(pos)
    })
    .factor()?;

    let mut distance = 0;
    for (i, j) in candidates {
        if let Some(d) = distances.get(i, j) {
            if *d != u32::MAX {
                distance = distance.max(*d);
            }
        }
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{distance}");

    println!("{}", distances.map(|d| AsciiChar::from_int(*d)));
    Ok(())
}
