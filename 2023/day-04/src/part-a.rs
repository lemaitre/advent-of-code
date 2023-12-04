use anyhow::Result;
use ascii::{AsAsciiStr, AsciiStr};

mod game;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let mut s = 0;
    game::foreach(input, |_, played, result| {
        let n = played.intersection(result).count();

        if n > 0 {
            s += 1 << (n - 1);
        }
        Ok(())
    })?;
    println!("Part A:\n{s}");
    Ok(())
}
