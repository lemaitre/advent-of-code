use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, SplitExact,
};

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

// i64 overflows, but i128, f32 and f64 work
pub type Number = f32;

pub struct Hailstone {
    pub x: Number,
    pub y: Number,
    pub z: Number,
    pub dx: Number,
    pub dy: Number,
    pub dz: Number,
}

const WINDOW_MIN: Number = 200000000000000.0;
const WINDOW_MAX: Number = 400000000000000.0;
// const WINDOW_MIN: Number = 7.0;
// const WINDOW_MAX: Number = 27.0;

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut hailstones = Vec::new();

    for line in input.lines() {
        let [[x, y, z], [dx, dy, dz]]: [[Number; 3]; 2] = line
            .split_exact(AsciiChar::At)?
            .map(|coords| {
                coords
                    .split_exact(AsciiChar::Comma)?
                    .map(|coord| coord.trim().as_str().parse())
                    .factor()
                    .map_err(anyhow::Error::from)
            })
            .factor()?;
        hailstones.push(Hailstone {
            x,
            y,
            z,
            dx,
            dy,
            dz,
        });
    }

    let mut n = 0_usize;
    for (i, h0) in hailstones.iter().enumerate() {
        for h1 in &hailstones[..i] {
            let mut c = h0.dx * h1.dy - h1.dx * h0.dy;
            if c == 0.0 {
                continue;
            }

            let mut ac = (h1.x - h0.x) * h1.dy + (h0.y - h1.y) * h1.dx;
            let mut bc = (h1.x - h0.x) * h0.dy + (h0.y - h1.y) * h0.dx;

            // Ensures a and c are positive if and only if intersection is in the future
            if c < 0.0 {
                ac = -ac;
                bc = -bc;
                c = -c;
            }

            // Intersection must be in the future of both hailstones
            if ac < 0.0 || bc < 0.0 {
                continue;
            }

            let xc = c * h0.x + ac * h0.dx;
            let yc = c * h0.y + ac * h0.dy;

            // intersection is outside of test zone
            if xc < WINDOW_MIN * c || xc > WINDOW_MAX * c {
                continue;
            }
            if yc < WINDOW_MIN * c || yc > WINDOW_MAX * c {
                continue;
            }

            n += 1;
        }
    }
    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{n}");
    Ok(())
}
