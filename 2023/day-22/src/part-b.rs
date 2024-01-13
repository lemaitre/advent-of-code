use std::{collections::HashSet, time::Instant};

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

    let mut under = (0..bricks.len())
        .map(|_| Vec::<u16>::new())
        .collect::<Vec<_>>();
    let mut above = (0..bricks.len())
        .map(|_| Vec::<u16>::new())
        .collect::<Vec<_>>();

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

        brick.pos = brick_flat.pos + max_height * (N * N) as u16;

        let mut last = u16::MAX;
        let mut pos = brick_flat.pos as u8;
        let mut below = Vec::new();
        for _ in 0..brick_flat.len {
            let b = top_brick[pos as usize];
            if b != last && top_height[pos as usize] == max_height {
                below.push(b);
                above[b as usize].push(i as u16);
            }
            top_height[pos as usize] = max_height + zlen as u16;
            top_brick[pos as usize] = i as u16;
            pos += brick_flat.stride;
            last = b;
        }

        under[i] = below;
    }

    let mut sorted = (1..bricks.len() as u16).collect::<Vec<_>>();
    sorted.sort_by_key(|&i| bricks[i as usize].pos);

    let mut chained = (0..bricks.len())
        .map(|_| HashSet::<u16>::new())
        .collect::<Vec<_>>();
    let mut partially_chained = (0..bricks.len())
        .map(|_| HashSet::<u16>::new())
        .collect::<Vec<_>>();

    let mut n = 0_usize;
    let mut s = 0_usize;

    for &i in sorted.iter().rev() {
        let mut chain = HashSet::new();
        let mut partial_chain = HashSet::new();

        for &j in &above[i as usize] {
            let set = if under[j as usize] == [i] {
                &mut chain
            } else {
                &mut partial_chain
            };
            set.insert(j);
            set.extend(&chained[j as usize]);
            partial_chain.extend(&partially_chained[j as usize]);
            partial_chain.insert(j);
        }

        let mut stable = false;
        while !stable {
            stable = true;
            partial_chain.retain(|&j| {
                if under[j as usize]
                    .iter()
                    .all(|k| *k == i || chain.contains(k))
                {
                    stable = false;
                    chain.insert(j);
                    false
                } else {
                    true
                }
            });
        }

        n += chain.is_empty() as usize;
        s += chain.len();

        chained[i as usize] = chain;
        partially_chained[i as usize] = partial_chain;
    }

    let elapsed = timer.elapsed();
    println!("Elapsed: {elapsed:?}\nPart A: {n}\nPart B: {s}");
    Ok(())
}
