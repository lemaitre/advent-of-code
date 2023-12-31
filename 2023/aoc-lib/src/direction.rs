use std::fmt::Display;

use Direction::{East, North, South, West};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Direction {
    North,
    South,
    East,
    West,
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

impl Direction {
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
