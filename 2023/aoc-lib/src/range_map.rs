use std::{fmt::Display, ops::Range};

use crate::RangeSet;

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub struct RangeMap<K, V>(pub(crate) Vec<(Range<K>, V)>);

impl<K, V> Default for RangeMap<K, V> {
    fn default() -> Self {
        Self::new()
    }
}

impl<K: Display, V: Display> Display for RangeMap<K, V> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("{")?;
        let mut sep = "";
        for (r, v) in self.0.iter() {
            f.write_fmt(format_args!("{sep}{}..{}=>{v}", r.start, r.end))?;
            sep = ",";
        }
        f.write_str("}")?;
        Ok(())
    }
}

impl<K, V> RangeMap<K, V> {
    pub fn new() -> Self {
        Self(Vec::new())
    }
    pub fn with_capacity(capacity: usize) -> Self {
        Self(Vec::with_capacity(capacity))
    }
    pub fn clear(&mut self) {
        self.0.clear()
    }
    pub fn iter(&self) -> <&[(Range<K>, V)] as IntoIterator>::IntoIter {
        self.into_iter()
    }
}

impl<K> RangeMap<K, ()> {
    pub fn as_range_set(self) -> RangeSet<K> {
        RangeSet(self)
    }
}

impl<K, V> RangeMap<K, V>
where
    K: Eq,
    K: Ord,
    K: Clone,
    V: Eq,
{
    fn from_vec(mut data: Vec<(Range<K>, V)>) -> Self {
        data.sort_by_key(|(r, _)| r.start.clone());
        let n = data.len();
        let mut i = 0;

        for j in 1..n {
            if data[i].0.end >= data[j].0.start && data[i].1 == data[j].1 {
                data[i].0.end = (&data[i].0.end).max(&data[j].0.end).clone();
            } else {
                i += 1;
                if i != j {
                    unsafe {
                        std::mem::swap(
                            (&mut data[i] as *mut (Range<K>, V))
                                .as_mut()
                                .unwrap_unchecked(),
                            (&mut data[j] as *mut (Range<K>, V))
                                .as_mut()
                                .unwrap_unchecked(),
                        )
                    };
                }
            }
        }

        data.truncate(i + 1);
        Self(data)
    }
    pub fn extend(&mut self, iter: impl IntoIterator<Item = (Range<K>, V)>) {
        let mut data = std::mem::take(&mut self.0);
        data.extend(iter);
        *self = Self::from_vec(data);
    }
    pub fn add(&mut self, range: Range<K>, value: V) {
        let mut data = std::mem::take(&mut self.0);
        data.push((range, value));
        *self = Self::from_vec(data);
    }
    pub fn threeway<'a, W>(&'a self, other: &'a RangeMap<K, W>) -> RangeMap3Way<'a, K, V, W> {
        RangeMap3Way {
            start: None,
            left: self.0.as_slice(),
            right: other.0.as_slice(),
        }
    }

    pub fn union<'a, W>(&'a self, other: &'a RangeMap<K, W>) -> RangeMapUnion<'a, K, V, W> {
        RangeMapUnion {
            left: self.0.as_slice(),
            right: other.0.as_slice(),
        }
    }

    pub fn intersection<'a, W>(
        &'a self,
        other: &'a RangeMap<K, W>,
    ) -> RangeMapIntersection<'a, K, V, W> {
        RangeMapIntersection(self.threeway(other))
    }
}

impl<K, V> FromIterator<(Range<K>, V)> for RangeMap<K, V>
where
    K: Eq,
    K: Ord,
    K: Clone,
    V: Eq,
{
    fn from_iter<I: IntoIterator<Item = (Range<K>, V)>>(iter: I) -> Self {
        Self::from_vec(iter.into_iter().collect())
    }
}

impl<K, V> IntoIterator for RangeMap<K, V> {
    type Item = (Range<K>, V);

    type IntoIter = <Vec<(Range<K>, V)> as IntoIterator>::IntoIter;

    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}

impl<'a, K, V> IntoIterator for &'a RangeMap<K, V> {
    type Item = &'a (Range<K>, V);

    type IntoIter = <&'a [(Range<K>, V)] as IntoIterator>::IntoIter;

    fn into_iter(self) -> Self::IntoIter {
        self.0.iter()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum RangeMap3WayRange<'a, K, V, W> {
    Left(Range<K>, &'a (Range<K>, V)),
    Both(Range<K>, &'a (Range<K>, V), &'a (Range<K>, W)),
    Right(Range<K>, &'a (Range<K>, W)),
}

impl<K, V, W> RangeMap3WayRange<'_, K, V, W> {
    pub fn range(&self) -> &Range<K> {
        match self {
            RangeMap3WayRange::Left(r, _) => r,
            RangeMap3WayRange::Both(r, _, _) => r,
            RangeMap3WayRange::Right(r, _) => r,
        }
    }
}

#[derive(Debug)]
pub struct RangeMap3Way<'a, K, V, W> {
    start: Option<K>,
    left: &'a [(Range<K>, V)],
    right: &'a [(Range<K>, W)],
}

impl<'a, K, V, W> Iterator for RangeMap3Way<'a, K, V, W>
where
    K: Eq,
    K: Ord,
    K: Clone,
{
    type Item = RangeMap3WayRange<'a, K, V, W>;

    fn next(&mut self) -> Option<Self::Item> {
        use RangeMap3WayRange::*;
        let start = std::mem::take(&mut self.start);
        let mut left = self.left.first().map(|(r, _)| r.clone());
        let mut right = self.right.first().map(|(r, _)| r.clone());

        if let Some(start) = start {
            for r in left.iter_mut() {
                r.start = (&r.start).max(&start).clone();
            }
            for r in right.iter_mut() {
                r.start = (&r.start).max(&start).clone();
            }
        }
        match (left, right) {
            (None, None) => None,
            (None, Some(right)) => {
                let right_ref = &self.right[0];
                self.right = &self.right[1..];
                Some(Right(right, right_ref))
            }
            (Some(left), None) => {
                let left_ref = &self.left[0];
                self.left = &self.left[1..];
                Some(Left(left, left_ref))
            }
            (Some(left), Some(right)) => {
                let left_ref = &self.left[0];
                let right_ref = &self.right[0];
                if left.end <= right.start {
                    self.left = &self.left[1..];
                    Some(Left(left, left_ref))
                } else if right.end <= left.start {
                    self.right = &self.right[1..];
                    Some(Right(right, right_ref))
                } else {
                    match left.start.cmp(&right.start) {
                        std::cmp::Ordering::Less => {
                            self.start = Some(right.start.clone());
                            Some(Left(left.start..right.start, left_ref))
                        }
                        std::cmp::Ordering::Equal => match left.end.cmp(&right.end) {
                            std::cmp::Ordering::Less => {
                                self.left = &self.left[1..];
                                self.start = Some(left.end.clone());
                                Some(Both(left, left_ref, right_ref))
                            }
                            std::cmp::Ordering::Equal => {
                                self.left = &self.left[1..];
                                self.right = &self.right[1..];
                                Some(Both(left, left_ref, right_ref))
                            }
                            std::cmp::Ordering::Greater => {
                                self.right = &self.right[1..];
                                self.start = Some(right.end.clone());
                                Some(Both(right, left_ref, right_ref))
                            }
                        },
                        std::cmp::Ordering::Greater => {
                            self.start = Some(left.start.clone());
                            Some(Right(right.start..left.start, right_ref))
                        }
                    }
                }
            }
        }
    }
}

#[derive(Debug)]
pub struct RangeMapIntersection<'a, K, V, W>(RangeMap3Way<'a, K, V, W>);

impl<'a, K, V, W> Iterator for RangeMapIntersection<'a, K, V, W>
where
    K: Eq,
    K: Ord,
    K: Clone,
{
    type Item = (Range<K>, &'a (Range<K>, V), &'a (Range<K>, W));

    fn next(&mut self) -> Option<Self::Item> {
        loop {
            if let RangeMap3WayRange::Both(r, left, right) = self.0.next()? {
                return Some((r, left, right));
            }
        }
    }
}

#[derive(Debug)]
pub struct RangeMapUnion<'a, K, V, W> {
    left: &'a [(Range<K>, V)],
    right: &'a [(Range<K>, W)],
}

impl<'a, K, V, W> Iterator for RangeMapUnion<'a, K, V, W>
where
    K: Eq,
    K: Ord,
    K: Clone,
{
    type Item = Range<K>;

    fn next(&mut self) -> Option<Self::Item> {
        match (self.left.first(), self.right.first()) {
            (None, None) => None,
            (None, Some(right)) => {
                self.right = &self.right[1..];
                Some(right.0.clone())
            }
            (Some(left), None) => {
                self.left = &self.left[1..];
                Some(left.0.clone())
            }
            (Some(left), Some(right)) => {
                let mut range = if left.0.start < right.0.start {
                    self.left = &self.left[1..];
                    left.0.clone()
                } else {
                    self.right = &self.right[1..];
                    right.0.clone()
                };

                loop {
                    if let Some(left) = self.left.first() {
                        if left.0.start <= range.end {
                            self.left = &self.left[1..];
                            if range.end < left.0.end {
                                range.end = left.0.end.clone();
                            }
                            continue;
                        }
                    }
                    if let Some(right) = self.right.first() {
                        if right.0.start <= range.end {
                            self.right = &self.right[1..];
                            if range.end < right.0.end {
                                range.end = right.0.end.clone();
                            }
                            continue;
                        }
                    }
                    break;
                }
                Some(range)
            }
        }
    }
}
