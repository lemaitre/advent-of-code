use std::time::Instant;

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, RangeMap, RangeSet, SplitExact, SplitExactWhitespace, SplitWhitespace,
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
    let mut seeds = Vec::new();
    let mut lines = input.lines();
    let [_, seed_line] = lines
        .next()
        .ok_or(anyhow!("Missing seed line"))?
        .split_exact(AsciiChar::Colon)?;
    let mut seed_it = seed_line.split_whitespace();
    while let Some((start, len)) = (seed_it.next(), seed_it.next()).factor() {
        let start = start.as_str().parse::<u64>()?;
        let len = len.as_str().parse::<u64>()?;
        seeds.push(start..start + len);
    }

    let mut seeds = seeds.into_iter().collect::<RangeSet<_>>();
    let mut seeds_target = RangeSet::new();
    _ = lines.next();

    let mut map = RangeMap::new();
    while lines.next().is_some() {
        map.clear();
        for line in lines.by_ref() {
            if line.is_empty() {
                break;
            }
            let [target_start, source_start, source_len]: [u64; 3] = line
                .split_exact_whitespace()?
                .map(|x| x.as_str().parse())
                .factor()?;
            map.add(source_start..source_start + source_len, target_start);
        }

        seeds_target.clear();
        seeds_target.extend(seeds.map_threeway(&map).filter_map(|which| match which {
            aoc_lib::RangeMap3WayRange::Left(range, _) => Some(range),
            aoc_lib::RangeMap3WayRange::Both(range, _, (target_range, target)) => Some(
                range.start + target - target_range.start..range.end + target - target_range.start,
            ),
            aoc_lib::RangeMap3WayRange::Right(_, _) => None,
        }));
        std::mem::swap(&mut seeds, &mut seeds_target);
    }
    let elapsed = timer.elapsed();
    println!(
        "Part B ({elapsed:?}):\n{}",
        seeds.iter().next().ok_or(anyhow!("no seeds"))?.start
    );
    Ok(())
}
