mod grid;
pub use grid::Grid;

use std::{fmt::Debug, mem::MaybeUninit};

use ascii::{AsciiChar, AsciiStr};
use thiserror::Error;

pub use ascii;

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
