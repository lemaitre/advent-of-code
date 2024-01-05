#![allow(unused)]

use std::ops::{Add, Range, Sub};

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Part<T = u16>(pub [T; 4]);

impl Part {
    pub const X: usize = 0;
    pub const M: usize = 1;
    pub const A: usize = 2;
    pub const S: usize = 3;
}

fn range_intersection<T>(a: &Range<T>, b: &Range<T>) -> Option<Range<T>>
where
    T: Clone,
    T: Ord,
{
    let start = (&a.start).max(&b.start);
    let end = (&a.end).min(&b.end);

    if start < end {
        Some(start.clone()..end.clone())
    } else {
        None
    }
}
impl<T> Part<Range<T>>
where
    T: Clone,
    T: Ord,
{
    pub fn intersection(&self, other: &Self) -> Option<Self> {
        Some(Part([
            range_intersection(&self.0[0], &other.0[0])?,
            range_intersection(&self.0[1], &other.0[1])?,
            range_intersection(&self.0[2], &other.0[2])?,
            range_intersection(&self.0[3], &other.0[3])?,
        ]))
    }
}

pub type ID = u16;

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WorkflowAction {
    #[default]
    Accept,
    Reject,
    Workflow(ID),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WorkflowComparison {
    LessThan,
    GreaterThan,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct WorkflowStep {
    pub category: u8,
    pub comparison: WorkflowComparison,
    pub value: u16,
    pub action: WorkflowAction,
}

impl WorkflowStep {
    pub fn check(&self, part: &Part) -> bool {
        let part_value = part.0[self.category as usize];
        match self.comparison {
            WorkflowComparison::LessThan => part_value < self.value,
            WorkflowComparison::GreaterThan => part_value > self.value,
        }
    }
}

#[derive(Debug, Default, Clone, PartialEq, Eq, Hash)]
pub struct Workflow {
    pub steps: Vec<WorkflowStep>,
    pub default_action: WorkflowAction,
}

impl Workflow {
    #[allow(unused)]
    pub fn check(&self, part: &Part) -> WorkflowAction {
        for step in self.steps.iter() {
            if step.check(part) {
                return step.action;
            }
        }
        self.default_action
    }
}
