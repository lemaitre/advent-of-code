use anyhow::Result;
use std::fmt::Display;
use thiserror::Error;

use aoc_lib::ascii::AsciiChar;

#[derive(Debug, Clone, Copy, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum Direction {
    North,
    South,
    East,
    West,
}

impl Direction {
    pub fn opposite(self) -> Self {
        match self {
            Direction::North => Direction::South,
            Direction::South => Direction::North,
            Direction::East => Direction::West,
            Direction::West => Direction::East,
        }
    }
    pub fn advance_from(self, pos: (isize, isize)) -> (isize, isize) {
        match self {
            Direction::North => (pos.0 - 1, pos.1),
            Direction::South => (pos.0 + 1, pos.1),
            Direction::East => (pos.0, pos.1 + 1),
            Direction::West => (pos.0, pos.1 - 1),
        }
    }
}

#[derive(Debug, Clone, Copy, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum Pipe {
    Ground,
    NorthSouth,
    EastWest,
    NorthEast,
    NorthWest,
    SouthEast,
    SouthWest,
    FourWay,
}

impl Display for Pipe {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Pipe::Ground => f.write_str("."),
            Pipe::NorthSouth => f.write_str("|"),
            Pipe::EastWest => f.write_str("-"),
            Pipe::NorthEast => f.write_str("L"),
            Pipe::NorthWest => f.write_str("J"),
            Pipe::SouthEast => f.write_str("F"),
            Pipe::SouthWest => f.write_str("7"),
            Pipe::FourWay => f.write_str("+"),
        }
    }
}

#[derive(Debug, Error)]
pub enum PipeParseError {
    #[error("{0} is not a valid pipe")]
    InvalidChar(AsciiChar),
}

impl Pipe {
    pub fn from_char(chr: &AsciiChar) -> Result<Self, PipeParseError> {
        match chr {
            AsciiChar::Dot => Ok(Pipe::Ground),
            AsciiChar::VerticalBar => Ok(Pipe::NorthSouth),
            AsciiChar::Minus => Ok(Pipe::EastWest),
            AsciiChar::L => Ok(Pipe::NorthEast),
            AsciiChar::J => Ok(Pipe::NorthWest),
            AsciiChar::F => Ok(Pipe::SouthEast),
            AsciiChar::_7 => Ok(Pipe::SouthWest),
            AsciiChar::S => Ok(Pipe::FourWay),
            _ => Err(PipeParseError::InvalidChar(*chr)),
        }
    }

    pub fn enter(self, dir: Direction) -> Option<Direction> {
        match (self, dir) {
            (Pipe::NorthSouth, Direction::North) => Some(Direction::South),
            (Pipe::NorthSouth, Direction::South) => Some(Direction::North),
            (Pipe::EastWest, Direction::East) => Some(Direction::West),
            (Pipe::EastWest, Direction::West) => Some(Direction::East),
            (Pipe::NorthEast, Direction::North) => Some(Direction::East),
            (Pipe::NorthEast, Direction::East) => Some(Direction::North),
            (Pipe::NorthWest, Direction::North) => Some(Direction::West),
            (Pipe::NorthWest, Direction::West) => Some(Direction::North),
            (Pipe::SouthEast, Direction::South) => Some(Direction::East),
            (Pipe::SouthEast, Direction::East) => Some(Direction::South),
            (Pipe::SouthWest, Direction::South) => Some(Direction::West),
            (Pipe::SouthWest, Direction::West) => Some(Direction::South),
            _ => None,
        }
    }
}
