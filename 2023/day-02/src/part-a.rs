use anyhow::Result;

mod bag;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = std::str::from_utf8(content.as_ref()).expect("Input is not a valid UTF-8 file");
    solve(content).expect("Could not solve part A")
}

fn solve(input: &str) -> Result<()> {
    let limit = bag::Bag {
        red: 12,
        green: 13,
        blue: 14,
    };
    let mut s = 0;
    bag::foreach(input, |game_id, bag| {
        if bag.red <= limit.red && bag.green <= limit.green && bag.blue <= limit.blue {
            s += game_id;
        }
    })?;
    println!("Part A:\n{s}");
    Ok(())
}
