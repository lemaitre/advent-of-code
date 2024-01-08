use std::{ops::Range, time::Instant};

use anyhow::{anyhow, bail, Result};
use aoc_lib::{
    ascii::{AsAsciiStr, AsciiChar, AsciiStr},
    IntegerMap, SplitExact,
};
use workflow::Part;

mod workflow;

fn main() {
    let filename = std::env::args().nth(1).unwrap_or("input.txt".to_string());
    let content = std::fs::read(filename.as_ref() as &str).expect("Could not read input file");
    let content = content
        .as_ascii_str()
        .expect("Input is not a valid ASCII file");
    solve(content).expect("Could not solve part B")
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct WorkflowRange {
    range: Part<Range<u16>>,
    target: workflow::ID,
}

#[derive(Debug, Default, Clone, PartialEq, Eq, Hash)]
pub struct WokrflowExhaustive {
    maps: Vec<WorkflowRange>,
    accepted: Vec<Part<Range<u16>>>,
}

#[allow(unused)]
pub fn print_workflows(id2map: &IntegerMap<&AsciiStr, u16>, workflows: &[WokrflowExhaustive]) {
    println!("==========");
    for (i, workflow) in workflows.iter().enumerate() {
        println!("{i} ({})", id2map.value(i as u16));
        for Part(accepted) in &workflow.accepted {
            println!("  {accepted:?}");
        }
        for WorkflowRange {
            range: Part(range),
            target,
        } in &workflow.maps
        {
            println!("  {range:?} -> {target} ({})", id2map.value(*target));
        }
    }
    println!("----------");
}

fn solve(input: &AsciiStr) -> Result<()> {
    let timer = Instant::now();
    let mut id_map = IntegerMap::<&AsciiStr, u16>::with_capacity(580);
    let mut workflows = Vec::<WokrflowExhaustive>::with_capacity(580);

    let mut lines = input.lines();
    let mut start = 0;
    for line in lines.by_ref() {
        if line.is_empty() {
            break;
        }

        let [name, rest] = line.split_exact(AsciiChar::CurlyBraceOpen)?;
        let id = id_map.id(name);
        if name.as_slice() == [AsciiChar::i, AsciiChar::n] {
            start = id;
        }

        let mut maps = Vec::with_capacity(4);
        let mut accepted = Vec::new();
        let mut rest = rest[..rest.len() - 1].split(AsciiChar::Comma);
        let mut last = rest
            .next()
            .ok_or(anyhow!("No step specified in workflow {name}"))?;
        let mut ranges = Part([(); 4].map(|_| 1..4001_u16));
        for step in rest {
            let [condition, action] = last.split_exact(AsciiChar::Colon)?;
            let category = condition[0];
            let comparison = condition[1];
            let value = &condition[2..];

            let category = match category {
                AsciiChar::x => Part::X,
                AsciiChar::m => Part::M,
                AsciiChar::a => Part::A,
                AsciiChar::s => Part::S,
                _ => bail!("'{category}' is not a valid category"),
            } as u8;
            let value = value.as_str().parse()?;

            last = step;

            let current_range;
            let range = &mut ranges.0[category as usize];
            match comparison {
                AsciiChar::LessThan => {
                    if value > range.start {
                        if value < range.end {
                            current_range = range.start..value;
                            range.start = value;
                        } else {
                            current_range = std::mem::take(range);
                        }
                    } else {
                        continue;
                    }
                }
                AsciiChar::GreaterThan => {
                    let value = value + 1;
                    if value < range.end {
                        if value > range.start {
                            current_range = value..range.end;
                            range.end = value;
                        } else {
                            current_range = std::mem::take(range);
                        }
                    } else {
                        continue;
                    }
                }
                _ => bail!("'{comparison}' is not a valid comparison"),
            };
            let range = &ranges.0[category as usize];

            let mut current_ranges = ranges.clone();
            current_ranges.0[category as usize] = current_range;

            match action.as_slice() {
                [AsciiChar::A] => {
                    accepted.push(current_ranges);
                }
                [AsciiChar::R] => (),
                _ => maps.push(WorkflowRange {
                    range: current_ranges,
                    target: id_map.id(action),
                }),
            };

            if range.start == range.end {
                break;
            }
        }

        if !ranges.0.iter().any(|r| r.start == r.end) {
            match last.as_slice() {
                [AsciiChar::A] => {
                    accepted.push(ranges);
                }
                [AsciiChar::R] => (),
                _ => maps.push(WorkflowRange {
                    range: ranges,
                    target: id_map.id(last),
                }),
            };
        }

        workflows.resize(workflows.len().max(id as usize + 1), Default::default());
        workflows[id as usize] = WokrflowExhaustive { maps, accepted };
    }

    std::mem::drop(lines);

    while !workflows[start as usize].maps.is_empty() {
        // print_workflows(&id_map, &workflows);
        for i in 0..workflows.len() {
            let mut workflow = std::mem::take(&mut workflows[i]);
            for range in std::mem::take(&mut workflow.maps) {
                let target = &workflows[range.target as usize];
                workflow
                    .maps
                    .extend(target.maps.iter().filter_map(|target_range| {
                        Some(WorkflowRange {
                            range: range.range.intersection(&target_range.range)?,
                            target: target_range.target,
                        })
                    }));
                workflow.accepted.extend(
                    target
                        .accepted
                        .iter()
                        .filter_map(|target_accepted| range.range.intersection(target_accepted)),
                );
            }

            workflows[i] = workflow;
        }
    }
    // println!("{start}");
    // print_workflows(&id_map, &workflows);

    let s = workflows[start as usize]
        .accepted
        .iter()
        .map(|Part(ranges)| {
            (ranges[0].end - ranges[0].start) as u64
                * (ranges[1].end - ranges[1].start) as u64
                * (ranges[2].end - ranges[2].start) as u64
                * (ranges[3].end - ranges[3].start) as u64
        })
        .sum::<u64>();

    let elapsed = timer.elapsed();
    println!("Part B ({elapsed:?}):\n{s}");
    // example: 167409079868000
    Ok(())
}
