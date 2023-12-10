use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiStr},
    SplitExactWhitespace,
};

use crate::hand::Hand;

mod card;
mod hand;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let mut hands = Vec::<(Hand, u32)>::new();
    for line in input.lines() {
        let [hand, bid] = line.split_exact_whitespace()?;
        let hand: Hand = hand.as_str().parse()?;
        hands.push((Hand::new_with_joker(hand.cards()), bid.as_str().parse()?));
    }

    hands.sort_by_key(|x| x.0);

    let mut s = 0;
    for (i, (_, bid)) in hands.iter().enumerate() {
        s += (i as u32 + 1) * bid;
    }
    println!("Part B:\n{s}");
    Ok(())
}
