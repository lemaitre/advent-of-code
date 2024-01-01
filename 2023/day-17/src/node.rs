use crate::tag::Tag;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Node {
    pub i: isize,
    pub j: isize,
    pub t: Tag,
    pub cost: u32,
}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        other.cost.partial_cmp(&self.cost)
    }
}
impl Ord for Node {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        other.cost.cmp(&self.cost)
    }
}
