use std::collections::{HashMap, HashSet};

use anyhow::Result;
use ascii::{AsAsciiStr, AsciiChar, AsciiStr};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let mut symbols = HashSet::new();
    let mut numbers = HashMap::new();

    for (i, line) in input.split(AsciiChar::LineFeed).enumerate() {
        let mut number_start = None;

        for (j, ch) in line.into_iter().enumerate() {
            if ch.is_ascii_digit() {
                if number_start.is_none() {
                    number_start = Some(j);
                }
            } else {
                if let Some(number_start) = number_start {
                    numbers.insert((i as i32, number_start as i32), &line[number_start..j]);
                }
                number_start = None;

                if *ch != AsciiChar::Dot {
                    symbols.insert((i as i32, j as i32));
                }
            }
        }
        if let Some(number_start) = number_start {
            numbers.insert((i as i32, number_start as i32), &line[number_start..]);
        }
    }

    let mut s = 0;

    for ((i, j), n) in numbers {
        let mut has_neighbor = false;
        for i in i - 1..=i + 1 {
            for j in j - 1..=j + n.len() as i32 {
                if symbols.contains(&(i, j)) {
                    has_neighbor = true;
                }
            }
        }

        if has_neighbor {
            let n: i32 = n.as_str().parse()?;
            s += n;
        }
    }
    println!("Part A:\n{s}");
    Ok(())
}
