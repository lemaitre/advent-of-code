use aoc_lib::{abs_diff, ascii::AsciiChar, Factor, Grid};

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Mirror {
    Horizontal(usize),
    Vertical(usize),
}

impl Mirror {
    pub fn find(grid: &Grid<AsciiChar>, hsum: &[usize], vsum: &[usize], smudges: usize) -> Self {
        let w2 = (vsum.len() + 1) / 2;
        let h2 = (hsum.len() + 1) / 2;

        let mut i_candidate = 0;
        let mut j_candidate = 0;

        for i in 1..hsum.len() {
            if count_reflection(hsum, i) == smudges
                && (0..grid.cols() as isize)
                    .map(|j| {
                        let mut i0 = i as isize - 1;
                        let mut i1 = i as isize;
                        let mut s = 0;

                        while let Some((&x0, &x1)) = (grid.get(i0, j), grid.get(i1, j)).factor() {
                            i0 -= 1;
                            i1 += 1;
                            if x0 != x1 {
                                s += 1;
                            }
                        }
                        s
                    })
                    .sum::<usize>()
                    == smudges
                && (abs_diff(i, h2) < abs_diff(i_candidate, h2) || i_candidate == 0)
            {
                i_candidate = i;
            }
        }

        for j in 1..vsum.len() {
            if count_reflection(vsum, j) == smudges
                && grid
                    .iter()
                    .map(|row| count_reflection(row, j))
                    .sum::<usize>()
                    == smudges
                && (abs_diff(j, w2) < abs_diff(j_candidate, w2) || j_candidate == 0)
            {
                j_candidate = j;
            }
        }

        #[allow(clippy::if_same_then_else)]
        if i_candidate == 0 {
            Mirror::Vertical(j_candidate)
        } else if j_candidate == 0 {
            Mirror::Horizontal(i_candidate)
        } else if abs_diff(i_candidate, h2) < abs_diff(j_candidate, w2) {
            Mirror::Horizontal(i_candidate)
        } else {
            Mirror::Vertical(j_candidate)
        }
    }
}

fn count_reflection<T: Eq>(data: &[T], mid: usize) -> usize {
    let mut i = mid as isize - 1;
    let mut j = mid;
    let mut s = 0;
    while i >= 0 && j < data.len() {
        if data[i as usize] != data[j] {
            s += 1;
        }
        i -= 1;
        j += 1;
    }
    s
}

#[cfg(test)]
mod tests {
    use crate::mirror::count_reflection;

    #[test]
    pub fn reflection() {
        assert_eq!(count_reflection(&[0, 1, 1, 0], 2), 0);
        assert_eq!(count_reflection(&[1, 1, 1, 0], 2), 1);
        assert_eq!(count_reflection(&[1, 0, 1, 1, 0], 3), 0);
    }
}
