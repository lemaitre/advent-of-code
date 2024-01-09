use std::io::Write;
use std::time::Instant;

use anyhow::Result;
use aoc_lib::ascii::{AsAsciiStr, AsciiChar, AsciiStr};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

const N: usize = 3;

fn step(grid0: &mut [u64; 3 * 131], grid1: &[u64; 3 * 131], obstacles: &[u64; 3 * 131]) {
    let mut left = 0_u64;
    let mut center = grid1[0];
    for j in 0..N {
        let right = grid1[j + 1];
        let left1 = (center << 1) | (left >> 63);
        let right1 = (center >> 1) | (right << 63);
        grid0[j] = (left1 | right1 | grid1[j + N]) & !obstacles[j];
        left = center;
        center = right;
    }
    for j in N..grid0.len() - N {
        let right = grid1[j + 1];
        let left1 = (center << 1) | (left >> 63);
        let right1 = (center >> 1) | (right << 63);
        grid0[j] = (left1 | right1 | grid1[j - N] | grid1[j + N]) & !obstacles[j];
        left = center;
        center = right;
    }
    for j in grid0.len() - N..grid0.len() - 1 {
        let right = grid1[j + 1];
        let left1 = (center << 1) | (left >> 63);
        let right1 = (center >> 1) | (right << 63);
        grid0[j] = (left1 | right1 | grid1[j - N]) & !obstacles[j];
        left = center;
        center = right;
    }
    let j = grid0.len() - 1;
    let left1 = (center << 1) | (left >> 63);
    let right1 = center >> 1;
    grid0[j] = (left1 | right1 | grid1[j - N]) & !obstacles[j];
}

#[allow(unused)]
fn write_pbm(grid: &[u64; 3 * 131], filename: impl ToString) -> Result<()> {
    let mut pbm = std::fs::File::options()
        .create(true)
        .write(true)
        .open(filename.to_string())?;
    write!(pbm, "P4\n{} {}\n", 3 * 64, 131)?;
    for &cell in grid {
        for i in 0..8 {
            let byte = [(((cell >> (i * 8)) & 0xff) as u8).reverse_bits()];
            pbm.write_all(&byte)?;
        }
    }
    Ok(())
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut obstacles = [0_u64; 3 * 131];
    let mut grid0 = [0_u64; 3 * 131];
    let mut grid1 = [0_u64; 3 * 131];
    let mut grid0 = &mut grid0;
    let mut grid1 = &mut grid1;

    for (i, line) in input.lines().enumerate() {
        let obstacles_row = &mut obstacles[3 * i..3 * i + 3];

        let mut chars = line.into_iter();

        for obstacle_cell in obstacles_row {
            let mut k = 0_usize;

            for &chr in chars.by_ref().take(64) {
                *obstacle_cell |= ((chr == AsciiChar::Hash) as u64) << k;
                k += 1;
            }
            if k < 64 {
                *obstacle_cell |= u64::MAX << k;
                break;
            }
        }
    }
    // write_pbm(&obstacles, "outputs/obstacle.pbm")?;

    // Count exterior cells
    grid0[0] |= 1 << 0;
    grid0[2] |= 1 << 2;
    grid0[130 * 3] |= 1 << 0;
    grid0[130 * 3 + 2] |= 1 << 2;

    for _ in 0..64 {
        std::mem::swap(&mut grid0, &mut grid1);

        step(grid0, grid1, &obstacles);
    }

    let mut exterior = 0;
    for &cell in grid0.iter() {
        exterior += cell.count_ones();
    }
    // write_pbm(grid0, "outputs/exterior.pbm")?;

    // Count interior cells
    grid0.fill(0);
    grid0[65 * 3 + 1] |= 1 << 1;

    for _ in 0..65 {
        std::mem::swap(&mut grid0, &mut grid1);

        step(grid0, grid1, &obstacles);
    }

    let mut interior = 0;
    for &cell in grid0.iter() {
        interior += cell.count_ones();
    }
    // write_pbm(grid0, "outputs/interior.pbm")?;

    for _ in 65..129 {
        std::mem::swap(&mut grid0, &mut grid1);

        step(grid0, grid1, &obstacles);
    }

    let mut odd = 0;
    for &cell in grid0.iter() {
        odd += cell.count_ones();
    }
    // write_pbm(grid0, "outputs/odd.pbm")?;

    for _ in 129..130 {
        std::mem::swap(&mut grid0, &mut grid1);

        step(grid0, grid1, &obstacles);
    }

    let mut even = 0;
    for &cell in grid0.iter() {
        even += cell.count_ones();
    }
    // write_pbm(grid0, "outputs/even.pbm")?;

    let n: u64 = 202300;
    let s = n * n * even as u64
        + (n + 1) * n * odd as u64
        + n * exterior as u64
        + (n + 1) * interior as u64;

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{s}");

    Ok(())
}
