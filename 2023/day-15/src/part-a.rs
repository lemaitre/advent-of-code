use std::time::Instant;

use anyhow::Result;
use aoc_lib::ascii::{AsAsciiStr, AsciiChar, AsciiStr};

use crate::hasher::hash;

mod hasher;

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
    for line in input.lines() {
        for step in line.split(AsciiChar::Comma) {
            s += hash(step) as u32;
        }
    }
    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{s}");
    Ok(())
}
