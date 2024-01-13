use ascii::{AsciiChar, AsciiStr, AsciiString};
use num_enum::{IntoPrimitive, TryFromPrimitive};
use std::fmt::Display;
use thiserror::Error;

use Direction::{East, North, South, West};

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, IntoPrimitive, TryFromPrimitive,
)]
#[repr(u8)]
pub enum Direction {
    East = 0,
    South = 1,
    West = 2,
    North = 3,
}

impl Display for Direction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            East => "E",
            South => "S",
            West => "W",
            North => "N",
        };
        f.write_str(s)
    }
}

#[derive(Debug, Error)]
pub enum DirectionParseError {
    #[error("Could not convert empty string into a direction")]
    EmptyString,
    #[error("Could not convert character '{0}' into a direction")]
    InvalidChar(AsciiChar),
    #[error("Could not convert string \"{0}\" into a direction because it is too long")]
    StringTooLong(AsciiString),
}

impl Direction {
    pub const ALL: [Direction; 4] = [North, East, South, West];

    pub fn from_u8(value: u8) -> Self {
        unsafe {
            let layout = std::alloc::Layout::new::<Self>();
            let dir: *mut Self = std::alloc::alloc(layout).cast();
            let ptr = dir as *mut u8;
            *ptr = value & 3;
            *dir
        }
    }

    pub fn from_char(chr: AsciiChar) -> Result<Self, DirectionParseError> {
        match chr {
            AsciiChar::E | AsciiChar::R | AsciiChar::GreaterThan => Ok(East),
            AsciiChar::S | AsciiChar::D | AsciiChar::v | AsciiChar::V => Ok(South),
            AsciiChar::W | AsciiChar::L | AsciiChar::LessThan => Ok(West),
            AsciiChar::N | AsciiChar::U | AsciiChar::Caret => Ok(North),
            _ => Err(DirectionParseError::InvalidChar(chr)),
        }
    }
    pub fn from_ascii(s: &AsciiStr) -> Result<Self, DirectionParseError> {
        match s.as_slice() {
            [] => Err(DirectionParseError::EmptyString),
            [chr] => Self::from_char(*chr),
            _ => Err(DirectionParseError::StringTooLong(s.to_owned())),
        }
    }
    pub fn step(self, i: isize, j: isize) -> (isize, isize) {
        match self {
            East => (i, j + 1),
            South => (i + 1, j),
            West => (i, j - 1),
            North => (i - 1, j),
        }
    }
    pub fn stepu(self, i: usize, j: usize) -> (usize, usize) {
        match self {
            East => (i, j + 1),
            South => (i + 1, j),
            West => (i, j - 1),
            North => (i - 1, j),
        }
    }

    pub fn rotate_clockwise(self) -> Self {
        Self::from_u8(self as u8 + 1)
    }

    pub fn rotate_counter_clockwise(self) -> Self {
        Self::from_u8(self as u8 + 3)
    }
    pub fn rotate_left(self) -> Self {
        self.rotate_counter_clockwise()
    }
    pub fn rotate_right(self) -> Self {
        self.rotate_clockwise()
    }

    pub fn reflect(self) -> Self {
        Self::from_u8(self as u8 ^ 2)
    }

    pub fn reflect_vertical(self) -> Self {
        match self {
            East => West,
            South => South,
            West => East,
            North => North,
        }
    }

    pub fn reflect_horizontal(self) -> Self {
        match self {
            East => East,
            South => North,
            West => West,
            North => South,
        }
    }

    pub fn reflect_diagonal_forward(self) -> Self {
        match self {
            East => North,
            South => West,
            West => South,
            North => East,
        }
    }
    pub fn reflect_diagonal_backward(self) -> Self {
        match self {
            East => South,
            South => East,
            West => North,
            North => West,
        }
    }
}
