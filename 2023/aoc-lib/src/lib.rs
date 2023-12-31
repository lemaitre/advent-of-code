mod grid;
pub use grid::Grid;

mod factor_expand;
pub use factor_expand::{Expand, Factor};

mod math;
pub use math::{abs_diff, gcd, lcm};

mod char_ext;
pub use char_ext::CharExt;

mod union_find;
pub use union_find::UnionFind;

use std::{fmt::Debug, mem::MaybeUninit};

use ascii::{AsciiChar, AsciiStr};
use thiserror::Error;

pub use ascii;

mod range_map;
pub use range_map::{RangeMap, RangeMap3WayRange};

mod range_set;
pub use range_set::{RangeSet, RangeSet3WayRange};

mod direction;
pub use direction::Direction;

pub trait CollectExact<T> {
    type Error;
    fn collect_exact(self) -> Result<T, Self::Error>;
}

#[derive(Error, Debug)]
pub enum ArrayCollectExactError {
    #[error(
        "Iterator did not produce enough elements for the array (expected: {expected}, got: {got})"
    )]
    NotEnoughElement { expected: usize, got: usize },
    #[error(
        "Iterator produced too many elements for the array (expected: {expected}, got: {got})"
    )]
    TooManyElement { expected: usize, got: usize },
}

impl<T: Sized, I: Iterator<Item = T>, const N: usize> CollectExact<[T; N]> for I {
    type Error = ArrayCollectExactError;
    fn collect_exact(mut self) -> Result<[T; N], Self::Error> {
        let mut arr: [MaybeUninit<T>; N] = unsafe { MaybeUninit::uninit().assume_init() };
        let mut i = 0;
        let mut error = None;

        while i < N {
            match self.next() {
                Some(x) => {
                    arr[i].write(x);
                    i += 1;
                }
                None => {
                    error = Some(ArrayCollectExactError::NotEnoughElement {
                        expected: N,
                        got: i,
                    });
                    break;
                }
            }
        }
        if error.is_none() && self.next().is_some() {
            error = Some(ArrayCollectExactError::TooManyElement {
                expected: N,
                got: N + 1 + self.count(),
            });
        }
        if let Some(error) = error {
            for x in &mut arr[0..i] {
                unsafe { x.assume_init_drop() };
            }
            return Err(error);
        }

        Ok(arr.map(|x| unsafe { x.assume_init() }))
    }
}

pub trait SplitExact: Sized {
    type Element;
    type Error;
    fn split_exact<const N: usize>(self, el: Self::Element) -> Result<[Self; N], Self::Error>;
}

impl SplitExact for &str {
    type Element = char;

    type Error = ArrayCollectExactError;

    fn split_exact<const N: usize>(self, el: Self::Element) -> Result<[Self; N], Self::Error> {
        self.split(el).collect_exact()
    }
}

impl SplitExact for &AsciiStr {
    type Element = AsciiChar;

    type Error = ArrayCollectExactError;

    fn split_exact<const N: usize>(self, el: Self::Element) -> Result<[Self; N], Self::Error> {
        self.split(el).collect_exact()
    }
}

pub trait SplitExactWhitespace: Sized {
    type Error;
    fn split_exact_whitespace<const N: usize>(self) -> Result<[Self; N], Self::Error>;
}
impl SplitExactWhitespace for &str {
    type Error = ArrayCollectExactError;

    fn split_exact_whitespace<const N: usize>(self) -> Result<[Self; N], Self::Error> {
        self.split_whitespace().collect_exact()
    }
}

impl SplitExactWhitespace for &AsciiStr {
    type Error = ArrayCollectExactError;

    fn split_exact_whitespace<const N: usize>(self) -> Result<[Self; N], Self::Error> {
        self.split(AsciiChar::Space)
            .filter(|s| !s.is_empty())
            .collect_exact()
    }
}

pub trait SplitWhitespace: Sized {
    type Iter: Iterator<Item = Self>;
    fn split_whitespace(self) -> Self::Iter;
}

impl<'a> SplitWhitespace for &'a AsciiStr {
    type Iter = SplitWhitespaceAscii<'a>;

    fn split_whitespace(self) -> Self::Iter {
        Self::Iter { string: self }
    }
}

pub struct SplitWhitespaceAscii<'a> {
    string: &'a AsciiStr,
}

impl<'a> Iterator for SplitWhitespaceAscii<'a> {
    type Item = &'a AsciiStr;

    #[allow(clippy::mem_replace_with_default)]
    fn next(&mut self) -> Option<Self::Item> {
        let string = std::mem::replace(&mut self.string, Default::default()).trim_start();

        if string.is_empty() {
            return None;
        }

        for (i, ch) in string.into_iter().enumerate() {
            if ch.is_whitespace() {
                self.string = &string[i..];
                return Some(&string[..i]);
            }
        }
        Some(string)
    }
}

impl<'a> DoubleEndedIterator for SplitWhitespaceAscii<'a> {
    #[allow(clippy::mem_replace_with_default)]
    fn next_back(&mut self) -> Option<Self::Item> {
        let string = std::mem::replace(&mut self.string, Default::default()).trim_end();

        if string.is_empty() {
            return None;
        }

        let mut i = string.len();

        while i > 0 {
            if string[i - 1].is_whitespace() {
                self.string = &string[..i];
                return Some(&string[i..]);
            }
            i -= 1;
        }
        Some(string)
    }
}
