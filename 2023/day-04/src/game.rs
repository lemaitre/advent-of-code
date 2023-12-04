use std::collections::HashSet;

use anyhow::Result;
use aoc_lib::{SplitExact, SplitExactWhitespace};
use ascii::{AsciiChar, AsciiStr};

pub fn foreach(
    input: &AsciiStr,
    mut f: impl FnMut(usize, &HashSet<u32>, &HashSet<u32>) -> Result<()>,
) -> Result<()> {
    let mut num_played = HashSet::<u32>::with_capacity(5);
    let mut num_results = HashSet::<u32>::with_capacity(8);
    for line in input.lines() {
        num_played.clear();
        num_results.clear();

        let [card_id, card] = line.split_exact(AsciiChar::Colon)?;
        let [_, card_id] = card_id.split_exact_whitespace()?;
        let card_id: usize = card_id.as_str().parse()?;

        let [played, result] = card.split_exact(AsciiChar::VerticalBar)?;

        for num in played.split(AsciiChar::Space) {
            if num.is_empty() {
                continue;
            }
            num_played.insert(num.as_str().parse()?);
        }
        for num in result.split(AsciiChar::Space) {
            if num.is_empty() {
                continue;
            }
            num_results.insert(num.as_str().parse()?);
        }

        f(card_id, &num_played, &num_results)?;
    }

    Ok(())
}
