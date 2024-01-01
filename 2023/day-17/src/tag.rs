use std::ops::RangeInclusive;

use aoc_lib::Direction;
use num_enum::{IntoPrimitive, TryFromPrimitive};

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, TryFromPrimitive, IntoPrimitive,
)]
#[repr(u8)]
pub enum Tag {
    North1 = 0,
    North2 = 1,
    North3 = 2,
    South1 = 3,
    South2 = 4,
    South3 = 5,
    East1 = 6,
    East2 = 7,
    East3 = 8,
    West1 = 9,
    West2 = 10,
    West3 = 11,
}

impl Tag {
    pub const N_VARIANTS: u8 = 12;

    pub fn get_related_slice(self) -> RangeInclusive<usize> {
        match self {
            Tag::North1 => 0..=0,
            Tag::North2 => 0..=1,
            Tag::North3 => 0..=2,
            Tag::South1 => 3..=3,
            Tag::South2 => 3..=4,
            Tag::South3 => 3..=5,
            Tag::East1 => 6..=6,
            Tag::East2 => 6..=7,
            Tag::East3 => 6..=8,
            Tag::West1 => 9..=9,
            Tag::West2 => 9..=10,
            Tag::West3 => 9..=11,
        }
    }

    pub fn advance(self, dir: Direction) -> Option<Self> {
        match (dir, self) {
            (Direction::North, Self::North1) => Some(Self::North2),
            (Direction::North, Self::North2) => Some(Self::North3),
            (Direction::North, Self::North3 | Self::South1 | Self::South2 | Self::South3) => None,
            (Direction::North, _) => Some(Self::North1),
            (Direction::South, Self::South1) => Some(Self::South2),
            (Direction::South, Self::South2) => Some(Self::South3),
            (Direction::South, Self::South3 | Self::North1 | Self::North2 | Self::North3) => None,
            (Direction::South, _) => Some(Self::South1),
            (Direction::East, Self::East1) => Some(Self::East2),
            (Direction::East, Self::East2) => Some(Self::East3),
            (Direction::East, Self::East3 | Self::West1 | Self::West2 | Self::West3) => None,
            (Direction::East, _) => Some(Self::East1),
            (Direction::West, Self::West1) => Some(Self::West2),
            (Direction::West, Self::West2) => Some(Self::West3),
            (Direction::West, Self::West3 | Self::East1 | Self::East2 | Self::East3) => None,
            (Direction::West, _) => Some(Self::West1),
        }
    }
}
