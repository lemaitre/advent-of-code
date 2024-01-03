use std::{collections::HashMap, hash::Hash};

use num::{Bounded, FromPrimitive, Integer, ToPrimitive};

#[derive(Debug, Clone)]
pub struct IntegerMap<T, I> {
    value2int: HashMap<T, I>,
    int2value: Vec<T>,
}

impl<T, I> Default for IntegerMap<T, I> {
    fn default() -> Self {
        Self::new()
    }
}

impl<T, I> IntegerMap<T, I> {
    pub fn new() -> Self {
        Self {
            value2int: HashMap::new(),
            int2value: Vec::new(),
        }
    }
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            value2int: HashMap::with_capacity(capacity),
            int2value: Vec::with_capacity(capacity),
        }
    }
    pub fn clear(&mut self) {
        self.value2int.clear();
        self.int2value.clear();
    }
}

impl<T, I> IntegerMap<T, I>
where
    T: Clone,
    T: Hash,
    T: Eq,
    I: Integer,
    I: Bounded,
    I: FromPrimitive,
    I: ToPrimitive,
    I: Clone,
{
    pub fn id(&mut self, value: T) -> I {
        match self.value2int.entry(value.clone()) {
            std::collections::hash_map::Entry::Occupied(entry) => entry.get().clone(),
            std::collections::hash_map::Entry::Vacant(entry) => {
                let id = I::from_usize(self.int2value.len()).unwrap_or(I::max_value());
                self.int2value.push(value);
                entry.insert(id.clone());
                id
            }
        }
    }

    pub fn value(&self, id: I) -> T {
        self.int2value[id.to_usize().unwrap_or(usize::MAX)].clone()
    }
}
