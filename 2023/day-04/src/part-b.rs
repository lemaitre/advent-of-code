use anyhow::Result;
use ascii::{AsAsciiStr, AsciiStr};

mod game;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let mut cards = Vec::<usize>::with_capacity(300);

    game::foreach(input, |i, played, result| {
        let n = played.intersection(result).count();

        cards.resize(cards.len().max(i + n + 1), 0);
        let count = cards[i] + 1;
        cards[i] = count;

        for j in 0..n {
            cards[i + 1 + j] += count;
        }

        Ok(())
    })?;

    let mut s = 0;
    for n in cards {
        s += n;
    }
    println!("Part B:\n{s}");
    Ok(())
}
