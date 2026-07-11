# DICEX

A web recreation of **DICEX**, a DOS game I wrote in Turbo Pascal in 1994.

**▶ [Play it](https://rburton5403.github.io/dicex-web/)**

![DICEX](assets/logo.png)

## The game

Dice fall one at a time into a 9 × 13 well. You can slide them left and right on
the way down, but you can't rotate anything — a die is just a number.

Any horizontal or vertical run of touching dice that adds up to **6**, and then
adds up to **9**, is wiped off the board. That's the whole game, and it's where
the "69's" counter in the corner comes from.

    3 3 4 5     →   3+3 = 6, then 4+5 = 9   →   all four dice vanish
    4 5 6       →   4+5 = 9, then 6         →   also counts, order doesn't matter
    5 5 5       →   never hits 6 or 9       →   nothing happens

An empty cell breaks a run. Gravity applies to the *whole board*, not just the
active die, so everything left floating after a clear settles down and can chain
into new combinations. Clear seven 69's and the dice start falling faster.

| Key | |
|---|---|
| ← → | move |
| ↓ | drop one row |
| space | slam |
| P | pause |

## About the port

The game logic is a direct port of the original `PLAYAREA.PAS` and
`PLAYGAME.PAS` — the elimination scan, the scoring formula
(`sub69 × (50 + sub69 × 5)`), the level-up curve (`gravity = 100 div level + 10`
hundredths of a second) and the game-over test are all unchanged.

The dice, the border tile and the logo are the **original 1994 artwork**, not
redrawn. They were recovered by decoding the Borland BGI `.IMG` files the game
shipped with: 16-colour planar VGA bitmaps, four bitplanes interleaved per
scanline. Every pixel is byte-for-byte what the game drew in 640×480 VGA, and
the layout on screen uses the original's coordinates.

The title screen is the original opening too — `FILLWITHDICE(1500)` splattered
1500 random dice across the screen before the palette faded out.

Two things did change. The original had a coordinate-tracking bug where the
falling die's position could drift if another die happened to fall on the same
tick; that's fixed. And slam, pause and the high score are new — the 1994
version had none of them.

One original quirk was deliberately *kept*: the level counter never resets the
69's total, so once you pass seven, every single clear bumps your level. The
game gets brutal fast. It did in 1994 too.

## Running locally

    python3 -m http.server 8000

Then open <http://localhost:8000>. No build step, no dependencies.

## Original source

The Turbo Pascal sources are preserved in [`original/`](original/), exactly as
they were on disk — including the commented-out asm blocks and the file dated
June 1994.
