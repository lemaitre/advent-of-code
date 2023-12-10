use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, SplitExact, SplitExactWhitespace,
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
    let mut line_it = input.lines();
    // Parse Seeds
    let head = line_it.next().ok_or(anyhow!("No Header"))?;
    let [_, seeds] = head.split_exact(AsciiChar::Colon)?;
    let seeds = seeds
        .split(AsciiChar::Space)
        .filter_map(|seed| {
            if seed.is_empty() {
                None
            } else {
                seed.as_str().parse().ok()
            }
        })
        .collect::<Vec<u64>>();

    line_it.next();
    let mut maps = Vec::new();
    // Parse Maps
    while line_it.next().is_some() {
        let mut map: Vec<[u64; 3]> = Vec::new();
        loop {
            match line_it.next() {
                None => break,
                Some(line) => {
                    if line.is_empty() {
                        break;
                    }
                    map.push(
                        line.split_exact_whitespace()?
                            .map(|x| x.as_str().parse())
                            .factor()?,
                    );
                }
            }
        }
        map.sort_by_key(|x| x[1]);
        maps.push(map);
    }

    let mut d = u64::MAX;
    for mut idx in seeds {
        for map in &maps {
            match map.binary_search_by_key(&idx, |x| x[1]) {
                Ok(i) => idx = map[i][0],
                Err(0) => (),
                Err(i) => {
                    let [dst, src, n] = map[i - 1];
                    if idx < src + n {
                        idx = (idx - src) + dst;
                    }
                }
            };
        }
        d = d.min(idx);
    }

    println!("Part A:\n{d}");
    Ok(())
}
