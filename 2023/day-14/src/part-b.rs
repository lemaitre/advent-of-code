use std::{collections::HashMap, time::Instant};

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, Grid,
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
    for (di, dj) in [(-1_isize, 0_isize), (0, -1), (1, 0), (0, 1)] {
        let mut fixed = false;
        while !fixed {
            fixed = true;
            for i in 0..grid.rows() as isize {
                for j in 0..grid.cols() as isize {
                    if let Some([current, north]) =
                        grid.get_many_mut([(i, j), (i + di, j + dj)])?.factor()
                    {
                        if *current == AsciiChar::O && *north == AsciiChar::Dot {
                            fixed = false;
                            std::mem::swap(current, north);
                        }
                    }
                }
            }
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
