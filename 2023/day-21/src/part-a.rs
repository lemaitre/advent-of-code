use std::time::Instant;

use anyhow::Result;
use aoc_lib::ascii::{AsAsciiStr, AsciiChar, AsciiStr};
use bitvec::{bitarr, BitArr};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

type Bits = BitArr!(for 192);

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut obstacles = Vec::<Bits>::new();
    let mut grid0 = obstacles.clone();

    for line in input.lines() {
        let mut obstacles_row = bitarr!(1; 192);
        let mut row = bitarr!(0; 192);

        for (j, &chr) in line.into_iter().enumerate() {
            obstacles_row.set(j, chr == AsciiChar::Hash);
            row.set(j, chr == AsciiChar::S);
        }

        obstacles.push(obstacles_row);
        grid0.push(row);
    }
    let mut grid1 = (0..grid0.len())
        .map(|_| bitarr!(0; 192))
        .collect::<Vec<_>>();

    for _ in 0..64 {
        std::mem::swap(&mut grid0, &mut grid1);
        let mut previous = &grid1[0];
        let mut current = &grid1[1];

        for ((row, next), obstacle_row) in grid0[1..]
            .iter_mut()
            .zip(grid1[2..].iter())
            .zip(obstacles[1..].iter())
        {
            let mut left = *current;
            let mut right = *current;
            left.shift_left(1);
            right.shift_right(1);
            *row = (left | right | previous | next) & !*obstacle_row;

            previous = current;
            current = next;
        }
    }

    let mut s = 0;
    for row in grid0 {
        s += row.count_ones();
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{s}");
    Ok(())
}
