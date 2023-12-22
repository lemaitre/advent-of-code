use std::{
    fmt::Display,
    ops::{Index, IndexMut},
};

use thiserror::Error;

#[derive(Debug, Clone)]
pub struct Grid<T> {
    nrows: usize,
    ncols: usize,
    data: Vec<T>,
}

#[derive(Debug, Error)]
pub enum InfallibleError {}
#[derive(Debug, Error)]
pub enum GridAddRowError<E = InfallibleError> {
    #[error("Tried to add a row of length {got} to a grid {expected}-wide")]
    WrongSize { expected: usize, got: usize },
    #[error("Iteration error")]
    IterationError(#[from] E),
}

impl<T> Grid<T> {
    #[inline]
    pub fn new() -> Self {
        Self {
            nrows: 0,
            ncols: 0,
            data: Vec::new(),
        }
    }
    #[inline]
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            nrows: 0,
            ncols: 0,
            data: Vec::with_capacity(capacity),
        }
    }
    pub fn add_row<I: IntoIterator<Item = T>>(&mut self, iter: I) -> Result<(), GridAddRowError> {
        self.data.reserve(self.data.len() + self.ncols);
        self.data.extend(iter);

        let n = self.data.len() - self.nrows * self.ncols;
        if self.ncols == 0 {
            self.ncols = n;
        }
        if n != self.ncols {
            self.data.truncate(self.nrows * self.ncols);
            return Err(GridAddRowError::WrongSize {
                expected: self.ncols,
                got: n,
            });
        }

        self.nrows += 1;

        Ok(())
    }
    pub fn try_add_row<E, I: IntoIterator<Item = Result<T, E>>>(
        &mut self,
        iter: I,
    ) -> Result<(), GridAddRowError<E>> {
        self.data.reserve(self.data.len() + self.ncols);

        for x in iter {
            match x {
                Ok(x) => self.data.push(x),
                Err(e) => {
                    self.data.truncate(self.nrows * self.ncols);
                    return Err(GridAddRowError::IterationError(e));
                }
            }
        }

        let n = self.data.len() - self.nrows * self.ncols;
        if self.ncols == 0 {
            self.ncols = n;
        }
        if n != self.ncols {
            self.data.truncate(self.nrows * self.ncols);
            return Err(GridAddRowError::WrongSize {
                expected: self.ncols,
                got: n,
            });
        }

        self.nrows += 1;

        Ok(())
    }
    #[inline]
    fn idx(&self, i: isize, j: isize) -> Option<usize> {
        if i >= 0 && i < self.nrows as isize && j >= 0 && j < self.ncols as isize {
            Some(i as usize * self.ncols + j as usize)
        } else {
            None
        }
    }
    #[inline]
    pub fn get(&self, i: isize, j: isize) -> Option<&T> {
        self.idx(i, j).map(|idx| &self.data[idx])
    }
    #[inline]
    pub fn get_mut(&mut self, i: isize, j: isize) -> Option<&mut T> {
        self.idx(i, j).map(|idx| &mut self.data[idx])
    }
    #[inline]
    pub fn iter(&self) -> GridIterator<'_, T> {
        GridIterator {
            ncols: self.ncols,
            data: &self.data,
        }
    }
    #[inline]
    pub fn iter_mut(&mut self) -> GridIteratorMut<'_, T> {
        GridIteratorMut {
            ncols: self.ncols,
            data: &mut self.data,
        }
    }
    #[inline]
    pub fn rows(&self) -> usize {
        self.nrows
    }
    #[inline]
    pub fn cols(&self) -> usize {
        self.ncols
    }
    #[inline]
    pub fn map<U>(&self, f: impl FnMut(&T) -> U) -> Grid<U> {
        Grid {
            nrows: self.nrows,
            ncols: self.ncols,
            data: self.data.iter().map(f).collect(),
        }
    }
    #[inline]
    pub fn clear(&mut self) {
        self.nrows = 0;
        self.ncols = 0;
        self.data.clear();
    }
}

impl<T: Clone> Grid<T> {
    #[inline]
    pub fn with_size(nrows: usize, ncols: usize, val: T) -> Self {
        let mut data = Vec::with_capacity(nrows * ncols);
        data.resize(nrows * ncols, val);
        Self { nrows, ncols, data }
    }
    #[inline]
    pub fn fill(&mut self, val: T) {
        self.data.fill(val)
    }
}

impl<T> Default for Grid<T> {
    #[inline]
    fn default() -> Self {
        Self::new()
    }
}

impl<T: Display> Display for Grid<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for row in self.iter() {
            for cell in row {
                f.write_fmt(format_args!("{cell}"))?;
            }
            f.write_str("\n")?;
        }
        Ok(())
    }
}

impl<T> Index<usize> for Grid<T> {
    type Output = [T];

    #[inline]
    fn index(&self, i: usize) -> &Self::Output {
        let idx = i * self.ncols;
        &self.data[idx..idx + self.ncols]
    }
}
impl<T> IndexMut<usize> for Grid<T> {
    #[inline]
    fn index_mut(&mut self, i: usize) -> &mut Self::Output {
        let idx = i * self.ncols;
        &mut self.data[idx..idx + self.ncols]
    }
}

pub struct GridIterator<'a, T> {
    ncols: usize,
    data: &'a [T],
}

impl<'a, T> Iterator for GridIterator<'a, T> {
    type Item = &'a [T];

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        if self.ncols > 0 && self.data.len() >= self.ncols {
            let (head, tail) = self.data.split_at(self.ncols);
            self.data = tail;
            Some(head)
        } else {
            None
        }
    }
}
pub struct GridIteratorMut<'a, T> {
    ncols: usize,
    data: &'a mut [T],
}

impl<'a, T> Iterator for GridIteratorMut<'a, T> {
    type Item = &'a mut [T];

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        if self.ncols > 0 && self.data.len() >= self.ncols {
            let data = std::mem::take(&mut self.data);
            let (head, tail) = data.split_at_mut(self.ncols);
            self.data = tail;
            Some(head)
        } else {
            None
        }
    }
}
