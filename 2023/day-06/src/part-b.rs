use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    CollectExact, SplitExact, SplitWhitespace,
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
    let [times, distances] = input
        .lines()
        .filter(|line| !line.is_empty())
        .collect_exact()?;
    let [_, times] = times.split_exact(AsciiChar::Colon)?;
    let [_, distances] = distances.split_exact(AsciiChar::Colon)?;

    let mut time = 0;
    let mut distance = 0;

    for (t, d) in times.split_whitespace().zip(distances.split_whitespace()) {
        time = time * 10_u64.pow(t.len() as u32) + t.as_str().parse::<u64>()?;
        distance = distance * 10_u64.pow(d.len() as u32) + d.as_str().parse::<u64>()?;
    }

    let mut count = 0;

    for speed in 0..time {
        let d = speed * (time - speed);
        if d > distance {
            count += 1;
        }
    }

    println!("Part B:\n{count}");
    Ok(())
}
