use std::{collections::BinaryHeap, time::Instant};

use anyhow::Result;
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiStr},
    CharExt, Direction, Factor, Grid,
};

mod tag;
use tag::Tag;

mod node;
use node::Node;

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
    let mut map = Grid::new();
    for line in input.lines() {
        map.try_add_row(line.into_iter().map(|chr| chr.to_int()))?;
    }

    let mut heat_loss = map.map(|_| [u32::MAX; Tag::N_VARIANTS as usize]);
    heat_loss[0][1][u8::from(Tag::East1) as usize] = map[0][1];
    heat_loss[1][0][u8::from(Tag::South1) as usize] = map[1][0];
    let mut heap = BinaryHeap::new();
    heap.push(Node {
        i: 0,
        j: 1,
        t: Tag::East1,
        cost: map[0][1],
    });
    heap.push(Node {
        i: 1,
        j: 0,
        t: Tag::South1,
        cost: map[1][0],
    });

    let mut loss = 0;

    while let Some(Node { i, j, t, cost }) = heap.pop() {
        if i as usize == map.rows() - 1 && j as usize == map.cols() - 1 {
            loss = cost;
            break;
        }

        for dir in [
            Direction::North,
            Direction::South,
            Direction::East,
            Direction::West,
        ] {
            let Some(t) = t.advance(dir) else {
                continue;
            };
            let (i, j) = dir.step(i, j);
            let Some((cell_cost, loss)) = (map.get(i, j), heat_loss.get_mut(i, j)).factor() else {
                continue;
            };

            let cost = cost + cell_cost;
            let cell_loss = &mut loss[u8::from(t) as usize];

            if *cell_loss > cost {
                *cell_loss = cost;
                heap.push(Node { i, j, t, cost });
            }
        }
    }

    for row in heat_loss.iter() {
        for cell in row.iter() {
            let x = cell.iter().min().copied().unwrap_or_default();
            print!(" {x}");
        }
        println!("");
    }

    let elapsed = timer.elapsed();
    println!("Part A ({elapsed:?}):\n{loss}");
    Ok(())
}
