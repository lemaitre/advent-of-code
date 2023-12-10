use std::mem::MaybeUninit;

pub trait Factor {
    type Output;

    fn factor(self) -> Self::Output;
}

pub trait Expand {
    type Output;

    fn expand(self) -> Self::Output;
}

impl<T, const N: usize> Factor for [Option<T>; N] {
    type Output = Option<[T; N]>;

    fn factor(self) -> Self::Output {
        let mut arr: [MaybeUninit<T>; N] = unsafe { MaybeUninit::uninit().assume_init() };

        for (i, x) in self.into_iter().enumerate() {
            match x {
                Some(x) => {
                    arr[i].write(x);
                }
                None => {
                    for x in &mut arr[0..i] {
                        unsafe { x.assume_init_drop() };
                    }
                    return None;
                }
            }
        }

        Some(arr.map(|x| unsafe { x.assume_init() }))
    }
}

impl<T, E, const N: usize> Factor for [Result<T, E>; N] {
    type Output = Result<[T; N], E>;

    fn factor(self) -> Self::Output {
        let mut arr: [MaybeUninit<T>; N] = unsafe { MaybeUninit::uninit().assume_init() };

        for (i, x) in self.into_iter().enumerate() {
            match x {
                Ok(x) => {
                    arr[i].write(x);
                }
                Err(e) => {
                    for x in &mut arr[0..i] {
                        unsafe { x.assume_init_drop() };
                    }
                    return Err(e);
                }
            }
        }

        Ok(arr.map(|x| unsafe { x.assume_init() }))
    }
}

impl<T, const N: usize> Expand for Option<[T; N]> {
    type Output = [Option<T>; N];

    fn expand(self) -> Self::Output {
        match self {
            Some(arr) => arr.map(Some),
            None => [(); N].map(|_| None),
        }
    }
}

impl<T, E: Clone, const N: usize> Expand for Result<[T; N], E> {
    type Output = [Result<T, E>; N];

    fn expand(self) -> Self::Output {
        match self {
            Ok(arr) => arr.map(Ok),
            Err(e) => [(); N].map(|_| Err(e.clone())),
        }
    }
}

impl<T> Factor for Vec<Option<T>> {
    type Output = Option<Vec<T>>;

    fn factor(self) -> Self::Output {
        let mut vec = Vec::with_capacity(self.capacity());

        for x in self {
            vec.push(x?);
        }

        Some(vec)
    }
}

impl<T, E> Factor for Vec<Result<T, E>> {
    type Output = Result<Vec<T>, E>;

    fn factor(self) -> Self::Output {
        let mut vec = Vec::with_capacity(self.capacity());

        for x in self {
            vec.push(x?);
        }

        Ok(vec)
    }
}

macro_rules! implement_tuple {
    ($($t:ident)*) => {
        impl<$($t,)*> Factor for ($(Option<$t>,)*) {
            type Output = Option<($($t,)*)>;

            #[allow(non_snake_case)]
            fn factor(self) -> Self::Output {
                let ($($t,)*) = self;
                Some(($($t?,)*))
            }
        }

        impl<Err, $($t,)*> Factor for ($(Result<$t, Err>,)*) {
            type Output = Result<($($t,)*), Err>;

            #[allow(non_snake_case)]
            fn factor(self) -> Self::Output {
                let ($($t,)*) = self;
                Ok(($($t?,)*))
            }
        }

        impl<$($t,)*> Expand for Option<($($t,)*)> {
            type Output = ($(Option<$t>,)*);

            #[allow(non_snake_case)]
            fn expand(self) -> Self::Output {
                match self {
                    Some(($($t,)*)) => ($(Some($t),)*),
                    None => ($(Option::<$t>::None,)*),
                }
            }
        }

        impl<Err: Clone, $($t,)*> Expand for Result<($($t,)*), Err> {
            type Output = ($(Result<$t, Err>,)*);

            #[allow(non_snake_case)]
            fn expand(self) -> Self::Output {
                match self {
                    Ok(($($t,)*)) => ($(Ok($t),)*),
                    Err(e) => ($(Result::<$t, Err>::Err(e.clone()),)*),
                }
            }
        }
    };
}

implement_tuple!(A);
implement_tuple!(A B);
implement_tuple!(A B C);
implement_tuple!(A B C D);
implement_tuple!(A B C D E);
implement_tuple!(A B C D E F);
implement_tuple!(A B C D E F G);
implement_tuple!(A B C D E F G H);
