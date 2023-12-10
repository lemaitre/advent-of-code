use std::{fmt::Display, str::FromStr};

use anyhow::{anyhow, Error, Result};

#[derive(Debug, Clone, Copy, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum Card {
    Joker = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
    Seven = 7,
    Eight = 8,
    Nine = 9,
    Ten = 10,
    Jack = 11,
    Queen = 12,
    King = 13,
    Ace = 14,
}

impl Display for Card {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Card::Ace => f.write_str("A"),
            Card::King => f.write_str("K"),
            Card::Queen => f.write_str("Q"),
            Card::Jack => f.write_str("J"),
            Card::Ten => f.write_str("T"),
            Card::Nine => f.write_str("9"),
            Card::Eight => f.write_str("8"),
            Card::Seven => f.write_str("7"),
            Card::Six => f.write_str("6"),
            Card::Five => f.write_str("5"),
            Card::Four => f.write_str("4"),
            Card::Three => f.write_str("3"),
            Card::Two => f.write_str("2"),
            Card::Joker => f.write_str("J"),
        }
    }
}

impl FromStr for Card {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut chars = s.chars();
        let card = Card::from_char(
            chars
                .next()
                .ok_or(anyhow!("Empty string is not a valid card"))?,
        )?;

        if chars.next().is_some() {
            Err(anyhow!(
                "String of size {} ('{}') is not valid card",
                s.len(),
                s
            ))
        } else {
            Ok(card)
        }
    }
}

impl Card {
    pub fn score(self) -> u32 {
        match self {
            Card::Ace => 14,
            Card::King => 13,
            Card::Queen => 12,
            Card::Jack => 11,
            Card::Ten => 10,
            Card::Nine => 9,
            Card::Eight => 8,
            Card::Seven => 7,
            Card::Six => 6,
            Card::Five => 5,
            Card::Four => 4,
            Card::Three => 3,
            Card::Two => 2,
            Card::Joker => 1,
        }
    }

    pub fn from_char(s: char) -> Result<Self> {
        match s {
            'A' => Ok(Card::Ace),
            'K' => Ok(Card::King),
            'Q' => Ok(Card::Queen),
            'J' => Ok(Card::Jack),
            'T' => Ok(Card::Ten),
            '9' => Ok(Card::Nine),
            '8' => Ok(Card::Eight),
            '7' => Ok(Card::Seven),
            '6' => Ok(Card::Six),
            '5' => Ok(Card::Five),
            '4' => Ok(Card::Four),
            '3' => Ok(Card::Three),
            '2' => Ok(Card::Two),
            _ => Err(anyhow!("'{}' is not a valid card", s)),
        }
    }
}
