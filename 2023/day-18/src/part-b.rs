use std::time::Instant;

use anyhow::{bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Direction, SplitExactWhitespace,
};

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

    let mut area2 = 0_i64;
    let mut straight = 0_i64;
    let (mut direct, mut indirect) = (0_i64, 0_i64);
    let (mut i, mut j) = (0_i64, 0_i64);
    let mut last_dir: Option<Direction> = None;
    let mut first_dir = Direction::North;

    for line in input.lines() {
        let [_, _, spec] = line.split_exact_whitespace()?;
        let n = &spec[2..spec.len() - 2];
        let dir = spec[spec.len() - 2];
        let n = i64::from_str_radix(n.as_str(), 16)?;
        let dir = match dir {
            AsciiChar::_0 => Direction::East,
            AsciiChar::_1 => Direction::South,
            AsciiChar::_2 => Direction::West,
            AsciiChar::_3 => Direction::North,
            _ => bail!("{dir} is not a valid direction"),
        };

        let (ni, nj) = match dir {
            Direction::North => (i - n, j),
            Direction::South => (i + n, j),
            Direction::East => (i, j + n),
            Direction::West => (i, j - n),
        };

        area2 += i * nj - ni * j;

        if let Some(last_dir) = last_dir {
            if last_dir.rotate_right() == dir {
                direct += 1;
            } else {
                indirect += 1;
            }
        } else {
            first_dir = dir;
        }

        straight += n - 1;
        last_dir = Some(dir);
        (i, j) = (ni, nj);
    }

    if let Some(last_dir) = last_dir {
        if last_dir.rotate_right() == first_dir {
            direct += 1;
        } else {
            indirect += 1;
        }
    }

    let area =
        (2 * area2.abs() + 2 * straight + direct.min(indirect) + 3 * direct.max(indirect)) / 4;
    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{area}");
    Ok(())
}
