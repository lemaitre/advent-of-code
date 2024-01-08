use std::{fmt::Display, ops::Range};

use crate::{
    range_map::{RangeMap3Way, RangeMap3WayRange, RangeMapIntersection, RangeMapUnion},
    RangeMap,
};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct RangeSet<T>(pub(crate) RangeMap<T, ()>);

impl<T> Default for RangeSet<T> {
    fn default() -> Self {
        Self::new()
    }
}

impl<T> RangeSet<T> {
    pub fn new() -> Self {
        Self(RangeMap::new())
    }
    pub fn with_capacity(capacity: usize) -> Self {
        Self(RangeMap::with_capacity(capacity))
    }
    pub fn clear(&mut self) {
        self.0.clear()
    }

    pub fn as_range_map(self) -> RangeMap<T, ()> {
        self.0
    }
    pub fn iter(&self) -> RangeSetIter<'_, T> {
        self.into_iter()
    }
}

impl<T> RangeSet<T>
where
    T: Eq,
    T: Ord,
    T: Clone,
{
    fn from_vec(data: Vec<Range<T>>) -> Self {
        Self(data.into_iter().map(|r| (r, ())).collect())
    }

    pub fn extend(&mut self, iter: impl IntoIterator<Item = Range<T>>) {
        self.0.extend(iter.into_iter().map(|r| (r, ())));
    }
    pub fn add(&mut self, range: Range<T>) {
        self.0.add(range, ());
    }
    pub fn threeway<'a>(&'a self, other: &'a RangeSet<T>) -> RangeSet3Way<'a, T> {
        RangeSet3Way(self.0.threeway(&other.0))
    }
    pub fn map_threeway<'a, V>(&'a self, other: &'a RangeMap<T, V>) -> RangeMap3Way<'a, T, (), V> {
        self.0.threeway(other)
    }

    pub fn union<'a>(&'a self, other: &'a RangeSet<T>) -> RangeSetUnion<'a, T> {
        RangeSetUnion(self.0.union(&other.0))
    }

    pub fn intersection<'a>(&'a self, other: &'a RangeSet<T>) -> RangeSetIntersection<'a, T> {
        RangeSetIntersection(self.0.intersection(&other.0))
    }
}

impl<T: Display> Display for RangeSet<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("{")?;
        let mut sep = "";
        for r in self.iter() {
            f.write_fmt(format_args!("{sep}{}..{}", r.start, r.end))?;
            sep = ",";
        }
        f.write_str("}")?;
        Ok(())
    }
}

impl<T> FromIterator<Range<T>> for RangeSet<T>
where
    T: Eq,
    T: Ord,
    T: Clone,
{
    fn from_iter<I: IntoIterator<Item = Range<T>>>(iter: I) -> Self {
        Self::from_vec(iter.into_iter().collect())
    }
}

#[derive(Debug, Clone)]
pub struct RangeSetIter<'a, T>(&'a [(Range<T>, ())]);

impl<'a, T> Iterator for RangeSetIter<'a, T> {
    type Item = &'a Range<T>;

    fn next(&mut self) -> Option<Self::Item> {
        match self.0.split_first() {
            Some(((r, ()), tail)) => {
                self.0 = tail;
                Some(r)
            }
            None => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct RangeSetIterOwned<T>(<Vec<(Range<T>, ())> as IntoIterator>::IntoIter);

impl<T> Iterator for RangeSetIterOwned<T> {
    type Item = Range<T>;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.next().map(|(r, ())| r)
    }
}

impl<T> IntoIterator for RangeSet<T> {
    type Item = Range<T>;

    type IntoIter = RangeSetIterOwned<T>;

    fn into_iter(self) -> Self::IntoIter {
        RangeSetIterOwned(self.0 .0.into_iter())
    }
}

impl<'a, T> IntoIterator for &'a RangeSet<T> {
    type Item = &'a Range<T>;

    type IntoIter = RangeSetIter<'a, T>;

    fn into_iter(self) -> Self::IntoIter {
        RangeSetIter(self.0 .0.as_slice())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum RangeSet3WayRange<T> {
    Left(Range<T>),
    Both(Range<T>),
    Right(Range<T>),
}

impl<T> RangeSet3WayRange<T> {
    pub fn range(&self) -> &Range<T> {
        match self {
            RangeSet3WayRange::Left(r) => r,
            RangeSet3WayRange::Both(r) => r,
            RangeSet3WayRange::Right(r) => r,
        }
    }
}

#[derive(Debug)]
pub struct RangeSet3Way<'a, T>(RangeMap3Way<'a, T, (), ()>);

impl<'a, T> Iterator for RangeSet3Way<'a, T>
where
    T: Eq,
    T: Ord,
    T: Clone,
{
    type Item = RangeSet3WayRange<T>;

    fn next(&mut self) -> Option<Self::Item> {
        match self.0.next() {
            Some(RangeMap3WayRange::Left(range, _)) => Some(RangeSet3WayRange::Left(range)),
            Some(RangeMap3WayRange::Both(range, _, _)) => Some(RangeSet3WayRange::Both(range)),
            Some(RangeMap3WayRange::Right(range, _)) => Some(RangeSet3WayRange::Right(range)),
            None => None,
        }
    }
}
#[derive(Debug)]
pub struct RangeSetIntersection<'a, T>(RangeMapIntersection<'a, T, (), ()>);

impl<'a, T> Iterator for RangeSetIntersection<'a, T>
where
    T: Eq,
    T: Ord,
    T: Clone,
{
    type Item = Range<T>;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.next().map(|(range, _, _)| range)
    }
}
#[derive(Debug)]
pub struct RangeSetUnion<'a, T>(RangeMapUnion<'a, T, (), ()>);

impl<'a, T> Iterator for RangeSetUnion<'a, T>
where
    T: Eq,
    T: Ord,
    T: Clone,
{
    type Item = Range<T>;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.next()
    }
}

#[cfg(test)]
#[allow(clippy::single_range_in_vec_init)]
mod tests {
    use super::*;

    #[test]
    fn from_iter() {
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .into_iter()
                .collect::<Vec<_>>(),
            vec![]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..1])
                .into_iter()
                .collect::<Vec<_>>(),
            vec![0..1]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..1, 1..2])
                .into_iter()
                .collect::<Vec<_>>(),
            vec![0..2]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([1..2, 0..1])
                .into_iter()
                .collect::<Vec<_>>(),
            vec![0..2]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..2, 4..5])
                .into_iter()
                .collect::<Vec<_>>(),
            vec![0..2, 4..5]
        );
        assert_eq!(
            RangeSet::<u32>::from_iter([0..2, 4..5, 1..6])
                .into_iter()
                .collect::<Vec<_>>(),
            vec![0..6]
        );
    }

    #[test]
    fn threeway() {
        use RangeSet3WayRange::*;
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .threeway(&RangeSet::<u32>::from_iter([]))
                .collect::<Vec<_>>(),
            vec![]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4, 6..8])
                .threeway(&RangeSet::<u32>::from_iter([]))
                .collect::<Vec<_>>(),
            vec![Left(0..4), Left(6..8)]
        );
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .threeway(&RangeSet::<u32>::from_iter([0..4, 6..8]))
                .collect::<Vec<_>>(),
            vec![Right(0..4), Right(6..8)]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4])
                .threeway(&RangeSet::<u32>::from_iter([2..6]))
                .collect::<Vec<_>>(),
            vec![Left(0..2), Both(2..4), Right(4..6)]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4, 10..12])
                .threeway(&RangeSet::<u32>::from_iter([2..6, 14..16]))
                .collect::<Vec<_>>(),
            vec![
                Left(0..2),
                Both(2..4),
                Right(4..6),
                Left(10..12),
                Right(14..16)
            ]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..6, 10..12])
                .threeway(&RangeSet::<u32>::from_iter([2..6, 12..16]))
                .collect::<Vec<_>>(),
            vec![Left(0..2), Both(2..6), Left(10..12), Right(12..16)]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..6, 10..16, 20..22])
                .threeway(&RangeSet::<u32>::from_iter([2..6, 12..16, 21..22]))
                .collect::<Vec<_>>(),
            vec![
                Left(0..2),
                Both(2..6),
                Left(10..12),
                Both(12..16),
                Left(20..21),
                Both(21..22)
            ]
        );
    }

    #[test]
    fn union() {
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .union(&RangeSet::<u32>::from_iter([]))
                .collect::<Vec<_>>(),
            vec![]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4, 6..8])
                .union(&RangeSet::<u32>::from_iter([]))
                .collect::<Vec<_>>(),
            vec![0..4, 6..8]
        );
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .union(&RangeSet::<u32>::from_iter([0..4, 6..8]))
                .collect::<Vec<_>>(),
            vec![0..4, 6..8]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4])
                .union(&RangeSet::<u32>::from_iter([2..6]))
                .collect::<Vec<_>>(),
            vec![0..6]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4, 10..12])
                .union(&RangeSet::<u32>::from_iter([2..6, 14..16]))
                .collect::<Vec<_>>(),
            vec![0..6, 10..12, 14..16,]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..6, 10..12])
                .union(&RangeSet::<u32>::from_iter([2..6, 12..16]))
                .collect::<Vec<_>>(),
            vec![0..6, 10..16]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..6, 10..16, 20..22])
                .union(&RangeSet::<u32>::from_iter([2..6, 12..16, 21..22]))
                .collect::<Vec<_>>(),
            vec![0..6, 10..16, 20..22,]
        );
    }

    #[test]
    fn intersection() {
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .intersection(&RangeSet::<u32>::from_iter([]))
                .collect::<Vec<_>>(),
            vec![]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4, 6..8])
                .intersection(&RangeSet::<u32>::from_iter([]))
                .collect::<Vec<_>>(),
            vec![]
        );
        assert_eq!(
            RangeSet::<u32>::from_iter([])
                .intersection(&RangeSet::<u32>::from_iter([0..4, 6..8]))
                .collect::<Vec<_>>(),
            vec![]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4])
                .intersection(&RangeSet::<u32>::from_iter([2..6]))
                .collect::<Vec<_>>(),
            vec![2..4]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..4, 10..12])
                .intersection(&RangeSet::<u32>::from_iter([2..6, 14..16]))
                .collect::<Vec<_>>(),
            vec![2..4]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..6, 10..12])
                .intersection(&RangeSet::<u32>::from_iter([2..6, 12..16]))
                .collect::<Vec<_>>(),
            vec![2..6]
        );

        assert_eq!(
            RangeSet::<u32>::from_iter([0..6, 10..16, 20..22])
                .intersection(&RangeSet::<u32>::from_iter([2..6, 12..16, 21..22]))
                .collect::<Vec<_>>(),
            vec![2..6, 12..16, 21..22]
        );
    }
}
