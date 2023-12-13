use std::{collections::HashMap, time::Instant};

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    SplitExact,
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
    let mut lines = input.lines();

    let directions = lines.next().ok_or(anyhow!("no directions given"))?;
    let mut graph = HashMap::new();

    for line in lines {
        if line.is_empty() {
            continue;
        }

        let [node, edges] = line.split_exact(AsciiChar::Equal)?.map(AsciiStr::trim);
        let [left, right] = edges.split_exact(AsciiChar::Comma)?.map(AsciiStr::trim);
        assert!(left[0] == AsciiChar::ParenOpen);
        assert!(right[right.len() - 1] == AsciiChar::ParenClose);
        let left = &left[1..];
        let right = &right[..right.len() - 1];

        graph.insert(node, (left, right));
    }

    let mut i = 0;
    let start = "AAA".as_ascii_str()?;
    let stop = "ZZZ".as_ascii_str()?;
    let mut current = start;

    while current != stop {
        let node = graph[current];
        let dir = directions[i % directions.len()];
        if dir == AsciiChar::L {
            current = node.0;
        } else {
            current = node.1;
        }
        i += 1;
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{i}");
    Ok(())
}
