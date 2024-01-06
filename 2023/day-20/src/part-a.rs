use std::time::Instant;

use anyhow::Result;
use aoc_lib::ascii::{AsAsciiStr, AsciiStr};

use crate::relay::Relays;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

mod relay;

#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Relay(i64, Vec<u8>);

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut relays = Relays::from_input(input)?;
    // println!("{relays}");

    let (mut low, mut high) = (0_u64, 0_u64);
    for _ in 0..1000 {
        let count = relays.trigger(relays.broadcast, false);
        low += count.low;
        high += count.high;
    }
    let elapsed = timer.elapsed();
    println!(
        "Part A ({elapsed:?}):\nlow: {low}\nhigh: {high}\n{}",
        low * high
    );
    Ok(())
}
