#![allow(unused)]

use std::fmt::Display;

use anyhow::{anyhow, Result};
use aoc_lib::{
    ascii::{AsciiChar, AsciiStr},
    SplitExactWhitespace,
};
use hashbrown::HashMap;

#[derive(Debug, Clone, Copy, Eq, PartialEq, PartialOrd, Ord, Hash)]
pub enum State {
    Unknown,
    Operational,
    Damaged,
}

impl State {
    pub fn from_char(chr: AsciiChar) -> Result<State> {
        match chr {
            AsciiChar::Question => Ok(State::Unknown),
            AsciiChar::Dot => Ok(State::Operational),
            AsciiChar::Hash => Ok(State::Damaged),
            _ => Err(anyhow!("{chr} is not a valid spring state")),
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct Report {
    states: Vec<State>,
    runs: Vec<u8>,
    cache: HashMap<(u8, u8), usize>,
}

impl Report {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn parse(&mut self, line: &AsciiStr, repeat: usize) -> Result<()> {
        self.states.clear();
        self.runs.clear();
        self.cache.clear();

        let [states, runs] = line.split_exact_whitespace()?;

        for i in 0..repeat {
            if i > 0 {
                self.states.push(State::Unknown);
            }
            for &chr in states.as_slice() {
                self.states.push(State::from_char(chr)?);
            }
            for run in runs.split(AsciiChar::Comma) {
                self.runs.push(run.as_str().parse()?);
            }
        }

        Ok(())
    }

    pub fn brute_force(&self) -> usize {
        let n = self.states.iter().filter(|&&s| s == State::Unknown).count();
        let mut count = 0;

        for mut i in 0..1_usize << n {
            let states = self
                .states
                .iter()
                .map(|&s| {
                    if s == State::Unknown {
                        let bit = i & 1;
                        i >>= 1;
                        if bit == 1 {
                            State::Damaged
                        } else {
                            State::Operational
                        }
                    } else {
                        s
                    }
                })
                .collect::<Vec<_>>();

            let mut runs = Vec::new();
            let mut run = 0;

            for &state in states.iter() {
                if state == State::Damaged {
                    run += 1;
                } else if run > 0 {
                    runs.push(run);
                    run = 0;
                }
            }
            if run > 0 {
                runs.push(run);
            }

            if runs == self.runs {
                count += 1;
            }
        }

        count
    }

    pub fn count(&mut self) -> usize {
        count_rec(&self.states, &self.runs, &mut self.cache, 0, 0)
    }
}

fn count_rec(
    springs: &[State],
    runs: &[u8],
    _cache: &mut HashMap<(u8, u8), usize>,
    spring_consumed: u8,
    run_consumed: u8,
) -> usize {
    if let Some(&count) = _cache.get(&(spring_consumed, run_consumed)) {
        return count;
    }
    if runs.len() <= run_consumed as usize {
        if spring_consumed as usize >= springs.len()
            || springs[spring_consumed as usize..]
                .iter()
                .all(|&s| s != State::Damaged)
        {
            return 1;
        } else {
            return 0;
        }
    }

    let mut count = 0;
    let run = runs[run_consumed as usize];

    for i in spring_consumed..=springs.len() as u8 - run {
        let j: u8 = i + run;
        if springs[i as usize..j as usize]
            .iter()
            .all(|&s| s != State::Operational)
            && (j as usize == springs.len() || springs[j as usize] != State::Damaged)
        {
            count += count_rec(springs, runs, _cache, j + 1, run_consumed + 1);
        }

        if springs[i as usize] == State::Damaged {
            break;
        }
    }

    _cache.insert((spring_consumed, run_consumed), count);
    count
}
