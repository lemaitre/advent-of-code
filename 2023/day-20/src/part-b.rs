use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiStr},
    lcm,
};

use crate::relay::Relays;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

mod relay;

#[derive(Debug, Default, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Relay(i64, Vec<u8>);

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut relays = Relays::from_input(input)?;
    let rx = relays.id("rx".as_ascii_str()?);
    relays.last = relays[rx].state.trailing_ones() as u8;

    let mut n = 1_u64;
    let mut remaining = relays[relays.broadcast].targets.len();
    let mut i = 0_u64;
    loop {
        i += 1;
        let count = relays.trigger(relays.broadcast, false);
        if count.last > 0 {
            remaining -= count.last as usize;
            n = lcm(n, i);
            if remaining == 0 {
                break;
            }
        }
    }

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{n}");
    Ok(())
}
