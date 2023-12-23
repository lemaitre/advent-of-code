use std::time::Instant;

use anyhow::{bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    SplitExact,
};

use crate::hasher::hash;

mod hasher;

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

    let mut boxes = [(); 256].map(|_| Vec::<(&AsciiStr, u8)>::new());
    for line in input.lines() {
        for step in line.split(AsciiChar::Comma) {
            if let Ok([label, focal]) = step.split_exact(AsciiChar::Equal) {
                let focal = focal.as_str().parse()?;
                let lense_box = &mut boxes[hash(label) as usize];
                let mut found = false;
                for (l, f) in lense_box.iter_mut() {
                    if *l == label {
                        *f = focal;
                        found = true;
                    }
                }
                if !found {
                    lense_box.push((label, focal));
                }
            } else {
                let [label, focal] = step.split_exact(AsciiChar::Minus)?;
                if !focal.is_empty() {
                    bail!("Removal should not specify a focal");
                }
                let lense_box = &mut boxes[hash(label) as usize];
                lense_box.retain(|&(l, _)| l != label);
            }
        }
    }

    let mut s = 0;

    for (i, lense_box) in boxes.iter().enumerate() {
        for (j, (_, f)) in lense_box.iter().enumerate() {
            s += (i + 1) * (j + 1) * *f as usize;
        }
    }
    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{s}");
    Ok(())
}
