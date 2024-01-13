use std::time::Instant;

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, SplitExact,
};

pub fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part A")
}

const N: u8 = 10;

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Brick {
    pub pos: u16,
    pub stride: u8,
    pub len: u8,
}

impl Brick {
    pub fn project_z(&self) -> (Brick, u16, u8) {
        let mut projected = *self;
        let zlen;
        let z = projected.z();
        projected.pos %= (N * N) as u16;
        if self.stride >= N * N {
            zlen = projected.len;
            projected.len = 1;
            projected.stride = 0;
        } else {
            zlen = 1;
        }
        (projected, z, zlen)
    }
    pub fn z(&self) -> u16 {
        self.pos / ((N * N) as u16)
    }
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut bricks = vec![Brick::default()];
    let mut height = 0;
    for line in input.lines() {
        let [start, end]: [[u16; 3]; 2] = line
            .split_exact(AsciiChar::Tilde)?
            .map(|coords| {
                coords
                    .split_exact(AsciiChar::Comma)?
                    .map(|coord| coord.as_str().parse())
                    .factor()
                    .map_err(anyhow::Error::from)
            })
            .factor()?;

        let mut brick = Brick {
            pos: 0,
            stride: 1,
            len: 1,
        };
        for (i, stride) in (0..3_usize).scan(1_u16, |stride, i| {
            let s = *stride as u8;
            *stride *= N as u16;
            Some((i, s))
        }) {
            let s = start[i];
            let e = end[i];
            if s != e {
                brick.len = (1 + e - s) as u8;
                brick.stride = stride;
            }
            brick.pos += s * stride as u16;
        }

        height = height.max(end[2]);
        bricks.push(brick);
    }
    bricks.sort_by_key(|brick| brick.pos);

    let mut support = (0..bricks.len()).map(|_| true).collect::<Vec<_>>();

    let mut top_height = [0_u16; (N * N) as usize];
    let mut top_brick = [0_u16; (N * N) as usize];

    for (i, brick) in bricks.iter_mut().enumerate() {
        let (brick_flat, _, zlen) = brick.project_z();

        let mut max_height = 0_u16;
        let mut pos = brick_flat.pos as u8;
        for _ in 0..brick_flat.len {
            max_height = max_height.max(top_height[pos as usize]);
            pos += brick_flat.stride;
        }

        let mut n_under = 0_u8;
        let mut last = u16::MAX;
        let mut pos = brick_flat.pos as u8;
        for _ in 0..brick_flat.len {
            let under = top_brick[pos as usize];
            n_under +=
                (under != last && under != 0 && top_height[pos as usize] == max_height) as u8;
            pos += brick_flat.stride;
            last = under;
        }
        brick.pos = brick_flat.pos + max_height * (N * N) as u16;

        let mut last = u16::MAX;
        let mut pos = brick_flat.pos as u8;
        for _ in 0..brick_flat.len {
            let under = top_brick[pos as usize];
            support[under as usize] &=
                !(n_under < 2 && under != last && top_height[pos as usize] == max_height);
            top_height[pos as usize] = max_height + zlen as u16;
            top_brick[pos as usize] = i as u16;
            pos += brick_flat.stride;
            last = under;
        }
    }

    let n = support.iter().copied().filter(|&b| b).count();

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{n}");
    Ok(())
}
