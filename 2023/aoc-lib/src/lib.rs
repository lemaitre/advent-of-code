mod grid;
pub use grid::Grid;

use std::fmt::{Debug, Display};

use ascii::{AsciiChar, AsciiStr};

pub use ascii;

pub trait CollectExact<T> {
    type Error;
    fn collect_exact(self) -> Result<T, Self::Error>;
}

#[derive(Debug, Clone)]
pub struct ArrayCollectExactError {}

impl std::error::Error for ArrayCollectExactError {}

impl Display for ArrayCollectExactError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("Cannot collect, wrong number of elements")
    }
}

impl<T, I: Iterator<Item = T>, const N: usize> CollectExact<[T; N]> for I {
    type Error = ArrayCollectExactError;
    fn collect_exact(self) -> Result<[T; N], Self::Error> {
        self.collect::<Vec<_>>()
            .try_into()
            .map_err(|_| ArrayCollectExactError {})
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
