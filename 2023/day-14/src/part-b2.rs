use std::{collections::HashMap, time::Instant};

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Grid,
};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

fn cycle(grid: &mut Grid<AsciiChar>) -> Result<()> {
    // North
    for j in 0..grid.cols() {
        let mut n = 0;
        for i in (0..grid.rows()).rev() {
            let cell = &mut grid[i][j];
            match *cell {
                AsciiChar::O => {
                    *cell = AsciiChar::Dot;
                    n += 1;
                }
                AsciiChar::Hash => {
                    for i in i + 1..i + n + 1 {
                        grid[i][j] = AsciiChar::O;
                    }
                    n = 0;
                }
                _ => (),
            }
        }
        for i in 0..n {
            grid[i][j] = AsciiChar::O;
        }
    }
    // West
    for i in 0..grid.rows() {
        let mut n = 0;
        for j in (0..grid.cols()).rev() {
            let cell = &mut grid[i][j];
            match *cell {
                AsciiChar::O => {
                    *cell = AsciiChar::Dot;
                    n += 1;
                }
                AsciiChar::Hash => {
                    for j in j + 1..j + n + 1 {
                        grid[i][j] = AsciiChar::O;
                    }
                    n = 0;
                }
                _ => (),
            }
        }
        for j in 0..n {
            grid[i][j] = AsciiChar::O;
        }
    }
    // South
    for j in 0..grid.cols() {
        let mut n = 0;
        for i in 0..grid.rows() {
            let cell = &mut grid[i][j];
            match *cell {
                AsciiChar::O => {
                    *cell = AsciiChar::Dot;
                    n += 1;
                }
                AsciiChar::Hash => {
                    for i in i - n..i {
                        grid[i][j] = AsciiChar::O;
                    }
                    n = 0;
                }
                _ => (),
            }
        }
        for i in grid.rows() - n..grid.rows() {
            grid[i][j] = AsciiChar::O;
        }
    }

    // West
    for i in 0..grid.rows() {
        let mut n = 0;
        for j in 0..grid.cols() {
            let cell = &mut grid[i][j];
            match *cell {
                AsciiChar::O => {
                    *cell = AsciiChar::Dot;
                    n += 1;
                }
                AsciiChar::Hash => {
                    for j in j - n..j {
                        grid[i][j] = AsciiChar::O;
                    }
                    n = 0;
                }
                _ => (),
            }
        }
        for j in grid.cols() - n..grid.cols() {
            grid[i][j] = AsciiChar::O;
        }
    }
    Ok(())
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut grid = Grid::new();

    for line in input.lines() {
        grid.add_row(line.as_slice().iter().copied())?;
    }

    let mut grid2time = HashMap::new();
    let mut time2grid = HashMap::new();

    let mut t = 0_usize;
    let cycle_start;
    loop {
        match grid2time.entry(grid.clone()) {
            std::collections::hash_map::Entry::Occupied(entry) => {
                cycle_start = *entry.get();
                break;
            }
            std::collections::hash_map::Entry::Vacant(entry) => {
                entry.insert(t);
                time2grid.insert(t, grid.clone());
            }
        }
        cycle(&mut grid)?;
        t += 1;
    }
    let cycle_len = t - cycle_start;
    let grid = &time2grid[&(cycle_start + (1000000000_usize - cycle_start) % cycle_len)];

    let s = grid
        .iter()
        .enumerate()
        .map(|(i, row)| (grid.rows() - i) * row.iter().filter(|&&chr| chr == AsciiChar::O).count())
        .sum::<usize>();

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{cycle_start} -> {t}: {s}");
    Ok(())
}
