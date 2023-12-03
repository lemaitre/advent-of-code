use anyhow::{anyhow, Result};

pub struct Bag {
    pub red: u32,
    pub green: u32,
    pub blue: u32,
}

pub fn foreach(input: &str, mut f: impl FnMut(u32, Bag)) -> Result<()> {
    for line in input.split_terminator('\n') {
        let (game_id, game) = line
            .split_once(':')
            .ok_or_else(|| anyhow!("Invalid game: {line}"))?;
        let (_, game_id) = game_id
            .split_once(' ')
            .ok_or_else(|| anyhow!("Invalid game ID: {game_id}"))?;
        let game_id: u32 = game_id.parse()?;
        let mut bag = Bag {
            red: 0,
            green: 0,
            blue: 0,
        };
        for pickup in game.split(';') {
            for ball in pickup.split(',') {
                let ball = ball.trim();
                let (n, color) = ball
                    .split_once(' ')
                    .ok_or_else(|| anyhow!("Invalid ball: {ball}"))?;
                let n: u32 = n.parse()?;

                match color {
                    "red" => bag.red = bag.red.max(n),
                    "green" => bag.green = bag.green.max(n),
                    "blue" => bag.blue = bag.blue.max(n),
                    _ => return Err(anyhow!("Invalid ball color: {color}")),
                }
            }
        }
        f(game_id, bag);
    }

    Ok(())
}
