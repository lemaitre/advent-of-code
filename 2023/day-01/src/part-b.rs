use anyhow::Result;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = std::str::from_utf8(content.as_ref()).expect("Input is not a valid UTF-8 file");
    solve(content).expect("Could not solve part B")
}

const NEEDLES: [(&str, u32); 20] = [
    ("0", 0),
    ("zero", 0),
    ("1", 1),
    ("one", 1),
    ("2", 2),
    ("two", 2),
    ("3", 3),
    ("three", 3),
    ("4", 4),
    ("four", 4),
    ("5", 5),
    ("five", 5),
    ("6", 6),
    ("six", 6),
    ("7", 7),
    ("seven", 7),
    ("8", 8),
    ("eight", 8),
    ("9", 9),
    ("nine", 9),
];

fn solve(input: &str) -> Result<()> {
    let mut s = 0;
    for line in input.split_terminator('\n') {
        let mut first = (i32::MAX, 0);
        let mut last = (i32::MIN, 0);
        for needle in NEEDLES {
            if let Some(i) = line.find(needle.0) {
                let i = i as i32;
                if i < first.0 {
                    first = (i, needle.1);
                }
            }
            if let Some(i) = line.rfind(needle.0) {
                let i = i as i32;
                if i > last.0 {
                    last = (i, needle.1);
                }
            }
        }

        s += first.1 * 10 + last.1;
    }

    println!("Part B:\n{s}");
    Ok(())
}
