use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, Grid,
};

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

    let mut grid = Grid::new();

    for line in input.lines() {
        grid.add_row(line.as_slice().iter().copied())?;
    }

    let mut fixed = false;
    let mut n = 0;
    while !fixed {
        n += 1;
        fixed = true;
        for i in 0..grid.rows() as isize {
            for j in 0..grid.cols() as isize {
                if let Some([current, north]) = grid.get_many_mut([(i, j), (i - 1, j)])?.factor() {
                    if *current == AsciiChar::O && *north == AsciiChar::Dot {
                        fixed = false;
                        std::mem::swap(current, north);
                    }
                }
            }
        }
    }

    let s = grid
        .iter()
        .enumerate()
        .map(|(i, row)| (grid.rows() - i) * row.iter().filter(|&&chr| chr == AsciiChar::O).count())
        .sum::<usize>();
    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}, {n} iter):\n{s}");
    Ok(())
}
