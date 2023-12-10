use std::{fmt::Display, str::FromStr};

use aoc_lib::{CollectExact, Factor};

use super::card::Card;

#[derive(Debug, Clone, Copy, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum HandType {
    HighCard,
    Pair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,
}

#[derive(Debug, Clone, Copy, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub struct Hand(HandType, [Card; 5]);

impl Display for Hand {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let cards = self.cards();
        f.write_fmt(format_args!(
            "{}{}{}{}{}",
            cards[0], cards[1], cards[2], cards[3], cards[4]
        ))
    }
}

impl FromStr for Hand {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Hand::new(
            s.chars().map(Card::from_char).collect_exact()?.factor()?,
        ))
    }
}

impl Hand {
    pub fn new(cards: [Card; 5]) -> Self {
        let mut counts = [0_u8; 16];
        for c in cards {
            counts[c.score() as usize] += 1;
        }

        let jokers = std::mem::take(&mut counts[Card::Joker.score() as usize]);

        counts.sort();

        let hand_type = if counts[15] + jokers == 5 {
            HandType::FiveOfAKind
        } else if counts[15] + jokers == 4 {
            HandType::FourOfAKind
        } else if counts[15] + jokers == 3 && counts[14] == 2 {
            HandType::FullHouse
        } else if counts[15] + jokers == 3 {
            HandType::ThreeOfAKind
        } else if counts[15] + jokers == 2 && counts[14] == 2 {
            HandType::TwoPair
        } else if counts[15] + jokers == 2 {
            HandType::Pair
        } else {
            HandType::HighCard
        };

        Self(hand_type, cards)
    }

    #[allow(dead_code)]
    pub fn new_with_joker(cards: [Card; 5]) -> Self {
        Self::new(cards.map(|c| if c == Card::Jack { Card::Joker } else { c }))
    }
    pub fn cards(&self) -> [Card; 5] {
        self.1
    }
}
