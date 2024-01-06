use std::{
    collections::{hash_map::Entry, HashMap, VecDeque},
    fmt::Display,
    ops::{Index, IndexMut},
};

use anyhow::Result;
use aoc_lib::{
    ascii::{AsciiChar, AsciiStr},
    SplitExact as _,
};
use arrayvec::ArrayVec;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Relay<'a> {
    pub name: &'a AsciiStr,
    pub state: i64,
    pub targets: ArrayVec<u8, 8>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Relays<'a> {
    name2id: HashMap<&'a AsciiStr, u8>,
    relays: ArrayVec<Relay<'a>, 64>,
    pub broadcast: u8,
    pub last: u8,
    queue: VecDeque<(u8, u8)>,
}

impl<'a> Index<u8> for Relays<'a> {
    type Output = Relay<'a>;

    fn index(&self, index: u8) -> &Self::Output {
        &self.relays[index as usize]
    }
}
impl<'a> IndexMut<u8> for Relays<'a> {
    fn index_mut(&mut self, index: u8) -> &mut Self::Output {
        &mut self.relays[index as usize]
    }
}

impl<'a> Display for Relays<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for (id, relay) in self.relays.iter().enumerate() {
            f.write_fmt(format_args!("{}({id}) {:x} -> ", relay.name, relay.state))?;

            let mut sep = "";
            for &target in &relay.targets {
                f.write_fmt(format_args!("{sep} {}({target})", self.name(target)))?;
                sep = ",";
            }
            f.write_str("\n")?;
        }
        Ok(())
    }
}

impl<'a> Relays<'a> {
    pub fn new() -> Self {
        Self::with_capacity(16)
    }
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            name2id: HashMap::with_capacity(64),
            relays: ArrayVec::new(),
            broadcast: 0,
            last: 0,
            queue: VecDeque::with_capacity(capacity),
        }
    }

    pub fn name(&self, id: u8) -> &'a AsciiStr {
        self.relays[id as usize].name
    }

    pub fn insert(&mut self, name: &'a AsciiStr, state: i64, targets: ArrayVec<u8, 8>) -> u8 {
        match self.name2id.entry(name) {
            Entry::Occupied(entry) => *entry.get(),
            Entry::Vacant(entry) => {
                let id = self.relays.len() as u8;
                entry.insert(id);
                self.relays.push(Relay {
                    name,
                    state,
                    targets,
                });
                id
            }
        }
    }

    pub fn id(&mut self, name: &'a AsciiStr) -> u8 {
        self.insert(name, i64::MAX, ArrayVec::new())
    }

    pub fn from_input(input: &'a AsciiStr) -> Result<Self> {
        let mut relays = Self::new();
        for line in input.lines() {
            let [name, targets] = line.split_exact(AsciiChar::Minus)?;
            let name = name.trim();
            let targets = targets[1..].trim();

            let id;
            match name[0] {
                AsciiChar::Ampersand => {
                    id = relays.id(&name[1..]);
                }
                AsciiChar::Percent => {
                    id = relays.id(&name[1..]);
                    relays[id].state = i64::MIN;
                }
                _ => {
                    id = relays.id(name);
                    relays.broadcast = id;
                }
            }

            let mut target_list = ArrayVec::new();

            for target in targets.split(AsciiChar::Comma) {
                let target = relays.id(target.trim());
                target_list.push(target);
                if relays[target].state >= 0 {
                    relays[target].state &= !(1_i64 << id);
                }
            }

            relays[id].targets = target_list;
        }

        Ok(relays)
    }

    pub fn trigger(&mut self, id: u8, high: bool) -> RelayCount {
        let mut count = RelayCount::default();
        self.queue.clear();

        let broadcast = self.broadcast;
        self[broadcast].state = [-1, 0][high as usize];
        self.queue.push_back((id | ((high as u8) << 7), id));

        while let Some((id, src)) = self.queue.pop_front() {
            let high = id >= 0x80;
            let id = id & 0x7f;

            count.low += (!high) as u64;
            count.high += high as u64;
            count.last += (id == self.last && high) as u64;

            // println!(
            //     "{}({src}) -{}-> {}({id}) {:x}",
            //     self.name(src),
            //     ["low", "high"][high as usize],
            //     self.name(id),
            //     self[id].state,
            // );

            let relay = &mut self.relays[id as usize];

            let mask;

            if high {
                // flip flop ignored
                if relay.state < 0 {
                    continue;
                }

                // conjunction
                relay.state |= 1_i64 << src;
                mask = ((relay.state != i64::MAX) as u8) << 7;
            } else {
                if relay.state < 0 {
                    relay.state ^= i64::MAX;
                    mask = (relay.state & 0x80) as u8;
                } else {
                    // conjunction
                    relay.state &= !(1_i64 << src);
                    mask = 0x80;
                }
            }

            self.queue
                .extend(relay.targets.iter().map(|&target| (target | mask, id)));
        }

        count
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct RelayCount {
    pub low: u64,
    pub high: u64,
    pub last: u64,
}
