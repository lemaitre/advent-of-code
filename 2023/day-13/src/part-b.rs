use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Grid,
};

mod mirror;
use mirror::Mirror;

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

    let mut grid = Grid::new();
    let mut hsum = Vec::new();
    let mut vsum = Vec::new();

    let mut di = 0;
    let mut dj = 0;
    for line in input.lines() {
        if line.is_empty() {
            match Mirror::find(&grid, &hsum, &vsum, 1) {
                Mirror::Horizontal(i) => di += i,
                Mirror::Vertical(j) => dj += j,
            }
            grid.clear();
            hsum.clear();
            vsum.clear();
        } else {
            grid.add_row(line.as_slice().iter().copied())?;
            hsum.push(
                line.as_slice()
                    .iter()
                    .filter(|&&chr| chr == AsciiChar::Hash)
                    .count(),
            );
            vsum.resize(line.len(), 0_usize);
            for (&chr, s) in line.as_slice().iter().zip(vsum.iter_mut()) {
                if chr == AsciiChar::Hash {
                    *s += 1;
                }
            }
        }
    }

    match Mirror::find(&grid, &hsum, &vsum, 1) {
        Mirror::Horizontal(i) => di += i,
        Mirror::Vertical(j) => dj += j,
    }
    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{}", di * 100 + dj);
    Ok(())
}
