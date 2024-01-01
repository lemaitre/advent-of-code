use ascii::AsciiChar;
use thiserror::Error;

pub trait CharExt {
    type ToIntError;
    fn from_int(i: u32) -> Self;
    fn to_int(self) -> Result<u32, Self::ToIntError>;
}

#[derive(Debug, Error)]
#[error("Could not convert {0} to integer")]
pub struct Char2IntError<C: std::fmt::Debug>(C);

impl CharExt for AsciiChar {
    type ToIntError = Char2IntError<AsciiChar>;

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

    fn to_int(self) -> Result<u32, Self::ToIntError> {
        match self {
            AsciiChar::_0 => Ok(0),
            AsciiChar::_1 => Ok(1),
            AsciiChar::_2 => Ok(2),
            AsciiChar::_3 => Ok(3),
            AsciiChar::_4 => Ok(4),
            AsciiChar::_5 => Ok(5),
            AsciiChar::_6 => Ok(6),
            AsciiChar::_7 => Ok(7),
            AsciiChar::_8 => Ok(8),
            AsciiChar::_9 => Ok(9),
            AsciiChar::a => Ok(10),
            AsciiChar::b => Ok(11),
            AsciiChar::c => Ok(12),
            AsciiChar::d => Ok(13),
            AsciiChar::e => Ok(14),
            AsciiChar::f => Ok(15),
            AsciiChar::g => Ok(16),
            AsciiChar::h => Ok(17),
            AsciiChar::i => Ok(18),
            AsciiChar::j => Ok(19),
            AsciiChar::k => Ok(20),
            AsciiChar::l => Ok(21),
            AsciiChar::m => Ok(22),
            AsciiChar::n => Ok(23),
            AsciiChar::o => Ok(24),
            AsciiChar::p => Ok(25),
            AsciiChar::q => Ok(26),
            AsciiChar::r => Ok(27),
            AsciiChar::s => Ok(28),
            AsciiChar::t => Ok(29),
            AsciiChar::u => Ok(30),
            AsciiChar::v => Ok(31),
            AsciiChar::w => Ok(32),
            AsciiChar::x => Ok(33),
            AsciiChar::y => Ok(34),
            AsciiChar::z => Ok(35),
            AsciiChar::A => Ok(36),
            AsciiChar::B => Ok(37),
            AsciiChar::C => Ok(38),
            AsciiChar::D => Ok(39),
            AsciiChar::E => Ok(40),
            AsciiChar::F => Ok(41),
            AsciiChar::G => Ok(42),
            AsciiChar::H => Ok(43),
            AsciiChar::I => Ok(44),
            AsciiChar::J => Ok(45),
            AsciiChar::K => Ok(46),
            AsciiChar::L => Ok(47),
            AsciiChar::M => Ok(48),
            AsciiChar::N => Ok(49),
            AsciiChar::O => Ok(50),
            AsciiChar::P => Ok(51),
            AsciiChar::Q => Ok(52),
            AsciiChar::R => Ok(53),
            AsciiChar::S => Ok(54),
            AsciiChar::T => Ok(55),
            AsciiChar::U => Ok(56),
            AsciiChar::V => Ok(57),
            AsciiChar::W => Ok(58),
            AsciiChar::X => Ok(59),
            AsciiChar::Y => Ok(60),
            AsciiChar::Z => Ok(61),
            _ => Err(Char2IntError(self)),
        }
    }
}

impl CharExt for char {
    type ToIntError = Char2IntError<char>;

    fn from_int(i: u32) -> Self {
        AsciiChar::from_int(i).as_char()
    }

    fn to_int(self) -> Result<u32, Char2IntError<char>> {
        let Ok(chr) = AsciiChar::from_ascii(self) else {
            return Err(Char2IntError(self));
        };
        match chr.to_int() {
            Ok(i) => Ok(i),
            Err(Char2IntError(chr)) => Err(Char2IntError(chr.as_char())),
        }
    }
}
