use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    SplitExact, SplitWhitespace,
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

    println!("strict graph {{");
    for line in input.lines() {
        let [node, neighbors] = line.split_exact(AsciiChar::Colon)?;
        for neighbor in neighbors.trim().split_whitespace() {
            println!("  {node} -- {neighbor}");
        }
    }
    println!("}}");

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{input}");
    Ok(())
}
