use aoc_lib::ascii::AsciiStr;

pub fn hash(s: &AsciiStr) -> u8 {
    let mut h = 0_u8;
    for &chr in s.as_bytes() {
        h = h.wrapping_add(chr);
        h = h.wrapping_mul(17);
    }
    h
}
