use std::time::Instant;

use anyhow::Result;
use aoc_lib::ascii::{AsAsciiStr, AsciiChar, AsciiStr};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

const N: usize = 3;
type Bits = [u64; N];

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut obstacles = Vec::<Bits>::new();
    let mut grid0 = obstacles.clone();

    for line in input.lines() {
        let mut obstacles_row = [0_u64; N];
        let mut row = [0_u64; N];

        let mut chars = line.into_iter();

        for i in 0.. {
            let mut j = 0_usize;
            let mut cell = 0_u64;
            let mut obstacle_cell = 0_u64;

            for &chr in chars.by_ref().take(64) {
                obstacle_cell |= ((chr == AsciiChar::Hash) as u64) << j;
                cell |= ((chr == AsciiChar::S) as u64) << j;
                j += 1;
            }
            obstacles_row[i] = obstacle_cell;
            row[i] = cell;
            if j < 64 {
                break;
            }
        }

        obstacles.push(obstacles_row);
        grid0.push(row);
    }
    let mut grid1 = (0..grid0.len()).map(|_| [0_u64; N]).collect::<Vec<_>>();

    for _ in 0..64 {
        std::mem::swap(&mut grid0, &mut grid1);
        let mut previous = &grid1[0];
        let mut current = &grid1[1];

        for ((row, next), obstacle_row) in grid0[1..]
            .iter_mut()
            .zip(grid1[2..].iter())
            .zip(obstacles[1..].iter())
        {
            let mut left = 0_u64;
            let mut center = current[0];
            for j in 0..N - 1 {
                let right = current[j + 1];
                let left1 = (center << 1) | (left >> 63);
                let right1 = (center >> 1) | (right << 63);
                row[j] = (left1 | right1 | previous[j] | next[j]) & !obstacle_row[j];
                left = center;
                center = right;
            }
            let j = N - 1;
            let right = 0_u64;
            let left1 = (center << 1) | (left >> 63);
            let right1 = (center >> 1) | (right << 63);
            row[j] = (left1 | right1 | previous[j] | next[j]) & !obstacle_row[j];

            previous = current;
            current = next;
        }
    }

    let mut s = 0;
    for row in &grid0 {
        for cell in row {
            s += cell.count_ones();
        }
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{s}");
    Ok(())
}
