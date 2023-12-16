#[derive(Debug, Default, Clone)]
pub struct Solver {
    cache: Vec<i64>,
}

impl Solver {
    pub fn extrapolate<E>(
        &mut self,
        numbers: impl Iterator<Item = Result<i64, E>>,
    ) -> Result<i64, E> {
        for x in numbers {
            let mut x1 = x?;

            for x0 in self.cache.iter_mut() {
                let d = x1 - *x0;
                *x0 = x1;
                x1 = d;
            }

            if x1 != 0 {
                self.cache.push(x1);
            }
        }

        let mut x0 = 0;
        for x1 in self.cache.iter_mut().rev() {
            *x1 += x0;
            x0 = *x1;
        }
        self.cache.clear();

        Ok(x0)
    }
}
