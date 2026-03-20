# Faro — A Card Game of the Old West

A visually striking Qt Quick application showcasing **Qt 6.8.3** capabilities, built as an interactive recreation of the historic card game **Faro** — the most popular gambling game in the American Wild West.

![Qt 6.8](https://img.shields.io/badge/Qt-6.8.3-41cd52)
![License](https://img.shields.io/badge/License-GPL--3.0-blue)
![Platforms](https://img.shields.io/badge/Platforms-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20WebAssembly-orange)

## Features

- **Full Faro Rules** — Authentic implementation: soda card, loser/winner dealing, coppered bets, splits, high card bets, and the dramatic last-three prediction
- **Case Keeper** — Abacus-style tracker showing which cards have appeared as winners, losers, or the soda
- **Rich Visual Design** — Dark saloon aesthetic with gold accents, card flip animations, ambient dust particles, vignette lighting, and cinematic transitions
- **Qt Quick Showcase** — Demonstrates `StackView` transitions, `Behavior` animations, `Canvas` grain overlay, `RadialGradient`, property bindings, custom QML components, and C++/QML integration

## Qt Modules Used

| Module | License | Purpose |
|---|---|---|
| Qt Core | LGPL-3.0 | Application foundation |
| Qt GUI | LGPL-3.0 | Windowing and rendering |
| Qt Quick | LGPL-3.0 | QML scene graph and UI |
| Qt Quick Controls | LGPL-3.0 | ApplicationWindow, StackView |
| Qt Multimedia | LGPL-3.0 | Sound effects (future) |

All modules are licensed under LGPL-3.0 or GPL-3.0. This application is open source under GPL-3.0.

## Project Structure

```
faro-qt/
├── CMakeLists.txt              # Build configuration
├── src/
│   ├── main.cpp                # Entry point, type registration
│   ├── gameengine.h/cpp        # Core Faro game logic
│   ├── cardmodel.h/cpp         # 13-card layout model
│   ├── playermodel.h/cpp       # Player state
│   └── casekeeper.h/cpp        # Card tracking
├── qml/
│   ├── Main.qml                # Root window, palette, ambient effects
│   ├── views/
│   │   ├── TitleScreen.qml     # Cinematic title with gold shimmer
│   │   ├── GameView.qml        # Main game table
│   │   └── ResultsView.qml     # End-of-game results
│   └── components/
│       ├── Card.qml            # Playing card with flip animation
│       ├── FaroTable.qml       # 13-card betting layout
│       ├── DealerBox.qml       # Soda / Loser / Deck / Winner
│       ├── CaseKeeper.qml      # Abacus-style card tracker
│       ├── ChipStack.qml       # Stacked chip visual
│       ├── BettingChip.qml     # Individual chip with copper
│       ├── CardFan.qml         # Decorative fanned cards
│       ├── ParticleOverlay.qml # Ambient dust particles
│       └── GoldText.qml        # Shimmer text effect
└── resources/
    └── *.png                   # Texture placeholders
```

## Building

### Prerequisites

- **Qt 6.8.3** with Qt Quick and Qt Multimedia
- **CMake 3.16+**
- **C++17 compiler** (GCC 11+, Clang 14+, MSVC 2022+)

### Desktop (Linux / macOS / Windows)

```bash
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/gcc_64
cmake --build . --parallel
./FaroGame
```

### WebAssembly

```bash
# Ensure emsdk is activated and Qt for WebAssembly is installed
source /path/to/emsdk/emsdk_env.sh

mkdir build-wasm && cd build-wasm
/path/to/Qt/6.8.3/wasm_singlethread/bin/qt-cmake ..
cmake --build . --parallel

# Serve locally
python3 -m http.server 8080
# Open http://localhost:8080/FaroGame.html
```

### Raspberry Pi (cross-compile)

```bash
mkdir build-pi && cd build-pi
cmake .. \
  -DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/pi_cross \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/pi-toolchain.cmake
cmake --build . --parallel
```

## Multiplayer Server

The multiplayer backend is a **Cloudflare Durable Object** (`Server/`) that manages game rooms over WebSockets.

### Prerequisites

- Node.js
- A Cloudflare account with the **Workers Paid plan** (required for Durable Objects)

### Build & Deploy

```bash
cd Server
npm install

# Authenticate with Cloudflare (one-time)
npx wrangler login

# Local development
npm run dev
# Worker available at http://localhost:8787

# Deploy to production
npm run deploy
```

After deploying, Wrangler prints the Worker URL:
```
https://pharaon-server.<your-subdomain>.workers.dev
```

Connect the Qt client via `wss://pharaon-server.<your-subdomain>.workers.dev`.

> **Note:** `wrangler.toml` contains a `v1` migration referencing `CounterRoom` (a removed class). If you hit a migration error on first deploy, delete that block:
> ```toml
> # Remove this block if deploying fresh:
> [[migrations]]
> tag = "v1"
> new_sqlite_classes = ["CounterRoom"]
> ```

---

## How to Play Faro

1. **Take a Seat** — Start from the title screen
2. **Place Bets** — Click cards on the felt layout to wager on them. Use the right panel to set bet size (1/5/10/25) and toggle the copper penny to reverse your bet
3. **Deal** — The dealer reveals a **loser** card (banker wins) and a **winner** card (player wins). If both cards share a rank, it's a **split** — the banker takes half
4. **Track Cards** — The case keeper on the left shows which cards have appeared. Green = winner, Red = loser, Gold = soda
5. **Repeat** — 25 turns total, with betting rounds between each deal
6. **Last Three** — When 3 cards remain, predict their order for a 4× payout

### Bet Types

- **Straight bet**: Click a card — you win if it's the winner
- **Coppered bet**: Toggle the copper penny, then click — you win if the card is the *loser*
- **High card**: Bet that the winner's rank will be higher than the loser's

## Visual Showcase

This application demonstrates several Qt Quick visual techniques:

- **Ambient particles** — 30 floating dust motes with randomized animation loops
- **Canvas grain overlay** — Film grain effect using `Canvas` with periodic repaints
- **Radial gradient vignette** — Atmospheric edge darkening
- **Card flip transform** — Y-axis `Rotation` with sequential animation
- **Gold shimmer** — Clipped rectangle sweep animation on text
- **Abacus beads** — Spring-loaded `OutBack` easing on case keeper dots
- **Confetti system** — Parallel animation on 50 particle rectangles
- **StackView transitions** — Opacity + scale push/pop transitions
- **Behavior animations** — Smooth reactive property changes throughout

## License

This project is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE) for details.

---

*"If you want to gamble, I tell you I'm your man — you win some, lose some, it's all the same to me."*
