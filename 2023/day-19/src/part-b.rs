use std::time::Instant;

use anyhow::{anyhow, bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    Factor, IntegerMap, SplitExact,
};

use crate::workflow::{Part, Workflow, WorkflowAction, WorkflowComparison, WorkflowStep};

mod workflow;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut id_map = IntegerMap::<&AsciiStr, workflow::ID>::new();
    let mut workflows = Vec::<Workflow>::new();

    let mut lines = input.lines();
    let mut start = 0;
    while let Some(line) = lines.next() {
        if line.is_empty() {
            break;
        }

        let [name, rest] = line.split_exact(AsciiChar::CurlyBraceOpen)?;
        let id = id_map.id(name);
        if name.as_slice() == &[AsciiChar::i, AsciiChar::n] {
            start = id;
        }

        let mut steps = Vec::new();
        let mut rest = rest[..rest.len() - 1].split(AsciiChar::Comma);
        let mut last = rest
            .next()
            .ok_or(anyhow!("No step specified in workflow {name}"))?;
        for step in rest {
            let [condition, action] = last.split_exact(AsciiChar::Colon)?;
            let category = condition[0];
            let comparison = condition[1];
            let value = &condition[2..];

            let category = match category {
                AsciiChar::x => workflow::X,
                AsciiChar::m => workflow::M,
                AsciiChar::a => workflow::A,
                AsciiChar::s => workflow::S,
                _ => bail!("'{category}' is not a valid category"),
            } as u8;
            let comparison = match comparison {
                AsciiChar::LessThan => WorkflowComparison::LessThan,
                AsciiChar::GreaterThan => WorkflowComparison::GreaterThan,
                _ => bail!("'{comparison}' is not a valid comparison"),
            };
            let value = value.as_str().parse::<u32>()?;
            let action = match action.as_slice() {
                [AsciiChar::A] => WorkflowAction::Accept,
                [AsciiChar::R] => WorkflowAction::Reject,
                _ => WorkflowAction::Workflow(id_map.id(action)),
            };

            steps.push(WorkflowStep {
                category,
                comparison,
                value,
                action,
            });

            last = step;
        }
        let default_action = match last.as_slice() {
            [AsciiChar::A] => WorkflowAction::Accept,
            [AsciiChar::R] => WorkflowAction::Reject,
            _ => WorkflowAction::Workflow(id_map.id(last)),
        };

        workflows.resize(workflows.len().max((id + 1) as usize), Default::default());
        workflows[id as usize] = Workflow {
            steps,
            default_action,
        };
    }

    std::mem::drop(lines);

    let mut s = 0_u64;

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{s}");
    // example: 167409079868000
    Ok(())
}
