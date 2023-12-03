use anyhow::{anyhow, Result};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = std::str::from_utf8(content.as_ref()).expect("Input is not a valid UTF-8 file");
    solve(content).expect("Could not solve part A")
}

fn solve(input: &str) -> Result<()> {
    let mut s = 0;
    for line in input.split_terminator('\n') {
        let mut first = ' ';
        let mut last = ' ';
        for c in line.chars() {
            if !c.is_numeric() {
                continue;
            }
            if first == ' ' {
                first = c;
            }
            last = c;
        }
        let first = first.to_digit(10).ok_or(anyhow!("first is not a digit"))?;
        let last = last.to_digit(10).ok_or(anyhow!("last is not a digit"))?;
        s += first * 10 + last;
    }

    println!("Part A:\n{s}");
    Ok(())
}
