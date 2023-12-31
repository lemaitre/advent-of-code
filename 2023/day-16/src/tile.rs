use std::fmt::Display;

use thiserror::Error;

use aoc_lib::{ascii::AsciiChar, Direction};

use Direction::{East, North, South, West};
use Tile::{BackwardMirror, Empty, ForwardMirror, HorizontalSplitter, VerticalSplitter};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Tile<T = bool> {
    Empty { horizontal: T, vertical: T },
    ForwardMirror { top_left: T, bottom_right: T },
    BackwardMirror { top_right: T, bottom_left: T },
    HorizontalSplitter { horizontal: T, vertical: T },
    VerticalSplitter { horizontal: T, vertical: T },
}

impl Display for Tile<bool> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Empty {
                horizontal: false,
                vertical: false,
            } => "⋅",
            Empty {
                horizontal: false,
                vertical: true,
            } => "│",
            Empty {
                horizontal: true,
                vertical: false,
            } => "─",
            Empty {
                horizontal: true,
                vertical: true,
            } => "┼",
            ForwardMirror {
                top_left: false,
                bottom_right: false,
            } => "╱",
            ForwardMirror {
                top_left: false,
                bottom_right: true,
            } => "┌",
            ForwardMirror {
                top_left: true,
                bottom_right: false,
            } => "┘",
            ForwardMirror {
                top_left: true,
                bottom_right: true,
            } => "┼",
            BackwardMirror {
                top_right: false,
                bottom_left: false,
            } => "╲",
            BackwardMirror {
                top_right: false,
                bottom_left: true,
            } => "┐",
            BackwardMirror {
                top_right: true,
                bottom_left: false,
            } => "└",
            BackwardMirror {
                top_right: true,
                bottom_left: true,
            } => "┼",
            HorizontalSplitter {
                horizontal: false,
                vertical: false,
            } => "═",
            HorizontalSplitter {
                horizontal: false,
                vertical: true,
            } => "╪",
            HorizontalSplitter {
                horizontal: true,
                vertical: false,
            } => "━",
            HorizontalSplitter {
                horizontal: true,
                vertical: true,
            } => "┿",
            VerticalSplitter {
                horizontal: false,
                vertical: false,
            } => "║",
            VerticalSplitter {
                horizontal: false,
                vertical: true,
            } => "┃",
            VerticalSplitter {
                horizontal: true,
                vertical: false,
            } => "╫",
            VerticalSplitter {
                horizontal: true,
                vertical: true,
            } => "╂",
        };
        f.write_str(s)
    }
}

#[derive(Debug, Error)]
#[error("Could not convert '{0}' into a tile")]
pub struct TileFromCharError(AsciiChar);

impl<T: Default> Tile<T> {
    pub fn from_char(chr: AsciiChar) -> Result<Self, TileFromCharError> {
        match chr {
            AsciiChar::Dot => Ok(Empty {
                horizontal: Default::default(),
                vertical: Default::default(),
            }),
            AsciiChar::Slash => Ok(ForwardMirror {
                top_left: Default::default(),
                bottom_right: Default::default(),
            }),
            AsciiChar::BackSlash => Ok(BackwardMirror {
                top_right: Default::default(),
                bottom_left: Default::default(),
            }),
            AsciiChar::Minus => Ok(HorizontalSplitter {
                horizontal: Default::default(),
                vertical: Default::default(),
            }),
            AsciiChar::VerticalBar => Ok(VerticalSplitter {
                horizontal: Default::default(),
                vertical: Default::default(),
            }),
            _ => Err(TileFromCharError(chr)),
        }
    }
}

impl<T> Tile<T> {
    pub fn get_from(&mut self, dir: Direction) -> &mut T {
        match (self, dir) {
            (Empty { vertical, .. }, North) => vertical,
            (Empty { vertical, .. }, South) => vertical,
            (Empty { horizontal, .. }, East) => horizontal,
            (Empty { horizontal, .. }, West) => horizontal,
            (ForwardMirror { top_left, .. }, North) => top_left,
            (ForwardMirror { bottom_right, .. }, South) => bottom_right,
            (ForwardMirror { bottom_right, .. }, East) => bottom_right,
            (ForwardMirror { top_left, .. }, West) => top_left,
            (BackwardMirror { top_right, .. }, North) => top_right,
            (BackwardMirror { bottom_left, .. }, South) => bottom_left,
            (BackwardMirror { top_right, .. }, East) => top_right,
            (BackwardMirror { bottom_left, .. }, West) => bottom_left,
            (HorizontalSplitter { vertical, .. }, North) => vertical,
            (HorizontalSplitter { vertical, .. }, South) => vertical,
            (HorizontalSplitter { horizontal, .. }, East) => horizontal,
            (HorizontalSplitter { horizontal, .. }, West) => horizontal,
            (VerticalSplitter { vertical, .. }, North) => vertical,
            (VerticalSplitter { vertical, .. }, South) => vertical,
            (VerticalSplitter { horizontal, .. }, East) => horizontal,
            (VerticalSplitter { horizontal, .. }, West) => horizontal,
        }
    }
    pub fn get_to(&mut self, dir: Direction) -> &mut T {
        self.get_from(dir.reflect())
    }
}

impl<T: std::ops::BitOr> Tile<T> {
    pub fn is_energized(self) -> <T as std::ops::BitOr>::Output {
        match self {
            Empty {
                horizontal,
                vertical,
            } => horizontal | vertical,
            ForwardMirror {
                top_left,
                bottom_right,
            } => top_left | bottom_right,
            BackwardMirror {
                top_right,
                bottom_left,
            } => top_right | bottom_left,
            HorizontalSplitter {
                horizontal,
                vertical,
            } => horizontal | vertical,
            VerticalSplitter {
                horizontal,
                vertical,
            } => horizontal | vertical,
        }
    }
}
