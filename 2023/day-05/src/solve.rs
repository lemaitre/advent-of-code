use std::ops::Range;

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsciiChar, AsciiStr},
    SplitExact, SplitWhitespace,
};

pub fn solve<'a, I: Iterator<Item = &'a AsciiStr> + 'a>(
    mut lines: I,
    seeds: Vec<Range<u64>>,
) -> Result<()> {
    let mut maps = Vec::new();
    while lines.next().is_some() {
        let mut map = Vec::new();
        while let Some(line) = lines.next() {
            if line.is_empty() {
                break;
            }
        }
    }
    Ok(())
}
