use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, SplitExact,
};
use ndarray_linalg::LeastSquaresSvdInPlace;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

// i64 overflows, but i128, f32 and f64 work
pub type Number = f64;

pub struct Hailstone {
    pub x: Number,
    pub y: Number,
    pub z: Number,
    pub dx: Number,
    pub dy: Number,
    pub dz: Number,
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();

    let mut hailstones = Vec::with_capacity(300);

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

    let mut x = ndarray::Array1::<f64>::zeros((6,));
    let mut y = ndarray::Array1::<f64>::zeros((3 * hailstones.len(),));
    let mut j = ndarray::Array2::<f64>::zeros((3 * hailstones.len(), 6));
    loop {
        for ((h, mut j), mut y) in hailstones
            .iter()
            .zip(j.axis_chunks_iter_mut(ndarray::Axis(0), 3))
            .zip(y.axis_chunks_iter_mut(ndarray::Axis(0), 3))
        {
            let xdiff = x[0] - h.x;
            let ydiff = x[1] - h.y;
            let zdiff = x[2] - h.z;
            let dxdiff = x[3] - h.dx;
            let dydiff = x[4] - h.dy;
            let dzdiff = x[5] - h.dz;

            j[(0, 0)] = dydiff;
            j[(0, 1)] = -dxdiff;
            j[(0, 2)] = 0.0;
            j[(0, 3)] = -ydiff;
            j[(0, 4)] = xdiff;
            j[(0, 5)] = 0.0;

            j[(1, 0)] = dzdiff;
            j[(1, 1)] = 0.0;
            j[(1, 2)] = -dxdiff;
            j[(1, 3)] = -zdiff;
            j[(1, 4)] = 0.0;
            j[(1, 5)] = xdiff;

            j[(2, 0)] = 0.0;
            j[(2, 1)] = dzdiff;
            j[(2, 2)] = -dydiff;
            j[(2, 3)] = 0.0;
            j[(2, 4)] = -zdiff;
            j[(2, 5)] = ydiff;

            y[0] = xdiff * dydiff - ydiff * dxdiff;
            y[1] = xdiff * dzdiff - zdiff * dxdiff;
            y[2] = ydiff * dzdiff - zdiff * dydiff;
        }

        let a = j.least_squares_in_place(&mut y)?;
        x -= &a.solution;
        if let Some(res) = a.residual_sum_of_squares {
            if res[()] < 1e-20 {
                break;
            }
        }
    }

    let z = x[2].round() as i64;
    let y = x[1].round() as i64;
    let x = x[0].round() as i64;

    let elapsed = timer.elapsed();
    println!(
        "Part B ({elapsed:?}):\nx: {x}\ty: {y}\tz: {z}\n{}",
        x + y + z
    );
    Ok(())
}
