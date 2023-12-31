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
    North = 0,
    South = 1,
    East = 2,
    West = 3,
}

impl Display for Direction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            North => "N",
            South => "S",
            East => "E",
            West => "W",
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
    pub fn from_char(chr: AsciiChar) -> Result<Self, DirectionParseError> {
        match chr {
            AsciiChar::N | AsciiChar::U | AsciiChar::Caret => Ok(North),
            AsciiChar::S | AsciiChar::D | AsciiChar::v | AsciiChar::V => Ok(South),
            AsciiChar::E | AsciiChar::R | AsciiChar::GreaterThan => Ok(East),
            AsciiChar::W | AsciiChar::L | AsciiChar::LessThan => Ok(West),
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
            North => (i - 1, j),
            South => (i + 1, j),
            East => (i, j + 1),
            West => (i, j - 1),
        }
    }

    pub fn rotate_clockwise(self) -> Self {
        match self {
            North => East,
            South => West,
            East => South,
            West => North,
        }
    }

    pub fn rotate_counter_clockwise(self) -> Self {
        match self {
            North => West,
            South => East,
            East => North,
            West => South,
        }
    }
    pub fn rotate_left(self) -> Self {
        self.rotate_counter_clockwise()
    }
    pub fn rotate_right(self) -> Self {
        self.rotate_clockwise()
    }

    pub fn reflect(self) -> Self {
        match self {
            North => South,
            South => North,
            East => West,
            West => East,
        }
    }

    pub fn reflect_vertical(self) -> Self {
        match self {
            North => North,
            South => South,
            East => West,
            West => East,
        }
    }

    pub fn reflect_horizontal(self) -> Self {
        match self {
            North => South,
            South => North,
            East => East,
            West => West,
        }
    }

    pub fn reflect_diagonal_forward(self) -> Self {
        match self {
            North => East,
            South => West,
            East => North,
            West => South,
        }
    }
    pub fn reflect_diagonal_backward(self) -> Self {
        match self {
            North => West,
            South => East,
            East => South,
            West => North,
        }
    }
}
