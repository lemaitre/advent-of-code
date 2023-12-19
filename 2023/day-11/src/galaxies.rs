use aoc_lib::{
    abs_diff,
    ascii::{AsciiChar, AsciiStr},
};

pub fn distance(input: &AsciiStr, expansion: usize) -> usize {
    let mut galaxies = Vec::new();
    let mut empty_rows = Vec::new();
    let mut empty_cols = Vec::new();

    for (i, line) in input.lines().enumerate() {
        empty_cols.resize(line.len(), expansion);
        let mut is_row_empty = expansion;

        for (j, chr) in line.as_slice().iter().enumerate() {
            if *chr == AsciiChar::Hash {
                is_row_empty = 1;
                galaxies.push((i, j));
                empty_cols[j] = 1;
            }
        }
        empty_rows.push(is_row_empty);
    }
    let galaxies = galaxies;

    let [rows_index, cols_index] = [empty_rows, empty_cols].map(|arr| {
        arr.iter()
            .scan(0, |a, b| {
                *a += *b;
                Some(*a)
            })
            .collect::<Vec<_>>()
    });

    let mut s = 0;
    for (k1, &(i1, j1)) in galaxies.iter().enumerate() {
        for &(i2, j2) in galaxies.iter().take(k1) {
            let di = abs_diff(rows_index[i1], rows_index[i2]);
            let dj = abs_diff(cols_index[j1], cols_index[j2]);

            s += di + dj;
        }
    }

    s
}
