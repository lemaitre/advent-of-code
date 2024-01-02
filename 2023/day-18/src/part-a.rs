use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiStr},
    Direction, Grid, SplitExactWhitespace, UnionFind,
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
    let timer = Instant::now();
    let mut trenches = Vec::new();
    let (mut i, mut j) = (0, 0);
    let (mut min_i, mut max_i, mut min_j, mut max_j) = (0, 0, 0, 0);

    for line in input.lines() {
        let [dir, n, _] = line.split_exact_whitespace()?;
        let dir = Direction::from_ascii(dir)?;
        let n = n.as_str().parse::<isize>()?;
        trenches.push((dir, n));
        match dir {
            Direction::North => i -= n,
            Direction::South => i += n,
            Direction::East => j += n,
            Direction::West => j -= n,
        }

        min_i = min_i.min(i);
        max_i = max_i.max(i);
        min_j = min_j.min(j);
        max_j = max_j.max(j);
    }

    let mut grid = Grid::with_size(
        (max_i - min_i + 1) as usize,
        (max_j - min_j + 1) as usize,
        false,
    );
    (i, j) = (-min_i, -min_j);

    let mut surface = 0;
    for (dir, n) in trenches {
        for _ in 0..n {
            let cell = &mut grid[i as usize][j as usize];
            surface += !*cell as u32;
            *cell = true;
            (i, j) = dir.step(i, j);
        }
    }

    let mut uf = UnionFind::<u32, u32>::new();
    uf.push(0).unwrap();
    let mut label_row0 = Vec::new();
    let mut label_row1 = Vec::new();
    let mut label_above = &mut label_row0;
    let mut label_current = &mut label_row1;
    label_above.resize(grid.cols(), 0_u32);
    label_current.resize(grid.cols(), 0_u32);

    let mut above = &grid[0];
    for row in grid.iter().skip(1) {
        let mut left = false;
        let mut label_left = 0;

        for (j, center) in row.iter().copied().enumerate() {
            if !center {
                let up = above[j];
                let label;
                match (left, up) {
                    (true, true) => {
                        label = uf.push(1).unwrap();
                    }
                    (true, false) => {
                        label = label_above[j];
                        *uf.features_mut(label) += 1;
                    }
                    (false, true) => {
                        label = label_left;
                        *uf.features_mut(label) += 1;
                    }
                    (false, false) => {
                        label = uf.merge(label_left, label_above[j]);
                        *uf.features_mut(label) += 1;
                    }
                }

                label_current[j] = label;
                label_left = label;
            }
            left = center;
        }

        if !left {
            uf.merge(label_left, 0);
        }

        above = row;
        std::mem::swap(&mut label_current, &mut label_above);
    }
    for (j, up) in above.iter().copied().enumerate() {
        if !up {
            uf.merge(label_above[j], 0);
        }
    }

    uf.transitive_closure();
    *uf.features_mut(0) = 0;

    for (_, s) in uf.inner().iter().copied() {
        surface += s;
    }

    let elapsed = timer.elapsed();

    println!("Part A ({elapsed:?}):\n{surface}");
    // answer: 48795
    Ok(())
}
