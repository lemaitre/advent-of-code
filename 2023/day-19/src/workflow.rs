#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Part(pub [u32; 4]);
pub const X: usize = 0;
pub const M: usize = 1;
pub const A: usize = 2;
pub const S: usize = 3;

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
    pub value: u32,
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
    pub fn check(&self, part: &Part) -> WorkflowAction {
        for step in self.steps.iter() {
            if step.check(part) {
                return step.action;
            }
        }
        self.default_action
    }
}
