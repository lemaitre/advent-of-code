use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiStr},
    SplitWhitespace,
};

mod utils;

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

    let mut s = 0;
    let mut solver = utils::Solver::default();

    for line in input.lines() {
        s += solver.extrapolate(line.split_whitespace().map(|s| s.as_str().parse()))?;
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{s}");
    Ok(())
}
