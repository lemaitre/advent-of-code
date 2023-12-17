use std::ops::AddAssign;

#[derive(Debug, Clone)]
pub struct UnionFind<L, F> {
    data: Vec<(L, F)>,
}

impl<L, F> Default for UnionFind<L, F> {
    fn default() -> Self {
        Self::new()
    }
}

impl<L, F> UnionFind<L, F> {
    pub fn new() -> Self {
        Self { data: Vec::new() }
    }
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            data: Vec::with_capacity(capacity),
        }
    }
}

impl<L, F> UnionFind<L, F>
where
    L: TryInto<usize>,
{
    pub fn parent(&self, label: L) -> &L {
        &self.data[label.try_into().unwrap_or(usize::MAX)].0
    }
    pub fn parent_mut(&mut self, label: L) -> &mut L {
        &mut self.data[label.try_into().unwrap_or(usize::MAX)].0
    }
    pub fn features(&self, label: L) -> &F {
        &self.data[label.try_into().unwrap_or(usize::MAX)].1
    }
    pub fn features_mut(&mut self, label: L) -> &mut F {
        &mut self.data[label.try_into().unwrap_or(usize::MAX)].1
    }
}

impl<L, F> UnionFind<L, F>
where
    L: TryFrom<usize>,
    L: Copy,
{
    pub fn push(&mut self, features: F) -> Option<L> {
        let Ok(l) = self.data.len().try_into() else {
            return None;
        };
        self.data.push((l, features));
        Some(l)
    }
}

impl<L, F> UnionFind<L, F>
where
    L: Copy,
    L: TryInto<usize>,
{
    pub fn iter(&self) -> UnionFindIterator<'_, L, F> {
        UnionFindIterator {
            i: 0,
            data: &self.data,
        }
    }

    pub fn inner(&self) -> &[(L, F)] {
        &self.data
    }
}
impl<L, F> UnionFind<L, F>
where
    L: Copy,
    L: TryInto<usize>,
    L: Ord,
{
    pub fn root(&self, mut label: L) -> L {
        loop {
            let l = *self.parent(label);
            if label <= l {
                return label;
            }
            label = l;
        }
    }
}

impl<L, F> UnionFind<L, F>
where
    L: Copy,
    L: TryInto<usize>,
    L: Ord,
    F: AddAssign,
    F: Default,
{
    pub fn merge(&mut self, mut l1: L, mut l2: L) -> L {
        l1 = self.root(l1);
        l2 = self.root(l2);

        if l1 == l2 {
            return l1;
        }

        if l1 > l2 {
            std::mem::swap(&mut l1, &mut l2);
        }

        let f = std::mem::take(self.features_mut(l2));
        *self.features_mut(l1) += f;
        *self.parent_mut(l2) = l1;

        l1
    }
}

#[derive(Debug, Clone)]
pub struct UnionFindIterator<'a, L, F> {
    i: usize,
    data: &'a [(L, F)],
}

impl<'a, L, F> Iterator for UnionFindIterator<'a, L, F>
where
    L: TryInto<usize>,
    L: Copy,
{
    type Item = (&'a L, &'a F);

    fn next(&mut self) -> Option<Self::Item> {
        loop {
            let i = self.i;
            if i >= self.data.len() {
                return None;
            }
            self.i += 1;

            let Ok(j) = self.data[i].0.try_into() else {
                return None;
            };
            if i == j {
                return Some((&self.data[i].0, &self.data[i].1));
            }
        }
    }
}

impl<'a, L, F> IntoIterator for &'a UnionFind<L, F>
where
    L: TryInto<usize>,
    L: Copy,
{
    type Item = (&'a L, &'a F);

    type IntoIter = UnionFindIterator<'a, L, F>;

    fn into_iter(self) -> Self::IntoIter {
        Self::IntoIter {
            i: 0,
            data: &self.data,
        }
    }
}
