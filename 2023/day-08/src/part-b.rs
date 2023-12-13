use std::{collections::HashMap, time::Instant};

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    lcm, SplitExact,
};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut lines = input.lines();

    let directions = lines.next().ok_or(anyhow!("no directions given"))?;
    let mut graph = HashMap::new();
    let mut currents = Vec::new();

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
        if node[2] == AsciiChar::A {
            currents.push(node);
        }
    }

    let mut combined = 1;

    for mut current in currents {
        let mut i = 0;
        while current[2] != AsciiChar::Z {
            let node = graph[current];
            let dir = directions[i % directions.len()];
            if dir == AsciiChar::L {
                current = node.0;
            } else {
                current = node.1;
            }
            i += 1;
        }

        combined = lcm(combined, i as u64);
    }

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{combined}");
    Ok(())
}
