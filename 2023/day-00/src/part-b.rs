use anyhow::Result;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = std::str::from_utf8(content.as_ref()).expect("Input is not a valid UTF-8 file");
    solve(content).expect("Could not solve part B")
}

fn solve(input: &str) -> Result<()> {
    println!("Part B:\n{input}");
    Ok(())
}
