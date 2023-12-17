use ascii::AsciiChar;

pub trait CharExt {
    fn from_int(i: u32) -> Self;
}

impl CharExt for AsciiChar {
    fn from_int(i: u32) -> Self {
        match i {
            0 => AsciiChar::_0,
            1 => AsciiChar::_1,
            2 => AsciiChar::_2,
            3 => AsciiChar::_3,
            4 => AsciiChar::_4,
            5 => AsciiChar::_5,
            6 => AsciiChar::_6,
            7 => AsciiChar::_7,
            8 => AsciiChar::_8,
            9 => AsciiChar::_9,
            10 => AsciiChar::a,
            11 => AsciiChar::b,
            12 => AsciiChar::c,
            13 => AsciiChar::d,
            14 => AsciiChar::e,
            15 => AsciiChar::f,
            16 => AsciiChar::g,
            17 => AsciiChar::h,
            18 => AsciiChar::i,
            19 => AsciiChar::j,
            20 => AsciiChar::k,
            21 => AsciiChar::l,
            22 => AsciiChar::m,
            23 => AsciiChar::n,
            24 => AsciiChar::o,
            25 => AsciiChar::p,
            26 => AsciiChar::q,
            27 => AsciiChar::r,
            28 => AsciiChar::s,
            29 => AsciiChar::t,
            30 => AsciiChar::u,
            31 => AsciiChar::v,
            32 => AsciiChar::w,
            33 => AsciiChar::x,
            34 => AsciiChar::y,
            35 => AsciiChar::z,
            36 => AsciiChar::A,
            37 => AsciiChar::B,
            38 => AsciiChar::C,
            39 => AsciiChar::D,
            40 => AsciiChar::E,
            41 => AsciiChar::F,
            42 => AsciiChar::G,
            43 => AsciiChar::H,
            44 => AsciiChar::I,
            45 => AsciiChar::J,
            46 => AsciiChar::K,
            47 => AsciiChar::L,
            48 => AsciiChar::M,
            49 => AsciiChar::N,
            50 => AsciiChar::O,
            51 => AsciiChar::P,
            52 => AsciiChar::Q,
            53 => AsciiChar::R,
            54 => AsciiChar::S,
            55 => AsciiChar::T,
            56 => AsciiChar::U,
            57 => AsciiChar::V,
            58 => AsciiChar::W,
            59 => AsciiChar::X,
            60 => AsciiChar::Y,
            61 => AsciiChar::Z,
            u32::MAX => AsciiChar::Dot,
            _ => AsciiChar::Plus,
        }
    }
}

impl CharExt for char {
    fn from_int(i: u32) -> Self {
        AsciiChar::from_int(i).as_char()
    }
}
