# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Pharaon** is a Qt 6.8.3 Quick application implementing the late 17th-century French gambling card game *pharaon* (anglicised as "Faro"). It serves as a Qt Quick showcase demonstrating C++/QML integration, animations, and visual effects. Target platforms: Windows, Linux, macOS, WebAssembly, Raspberry Pi.

## Build Commands

### Prerequisites
- Qt 6.8.3 with Qt Quick, Qt Quick Controls 2, and Qt Multimedia
- CMake 3.16+
- C++17 compiler (GCC 11+, Clang 14+, MSVC 2022+)

### Desktop Build
```bash
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/gcc_64
cmake --build . --parallel
./FaroGame
```

### WebAssembly Build
```bash
source /path/to/emsdk/emsdk_env.sh
mkdir build-wasm && cd build-wasm
/path/to/Qt/6.8.3/wasm_singlethread/bin/qt-cmake ..
cmake --build . --parallel
# Serve: python3 -m http.server 8080
```

### Raspberry Pi (cross-compile)
```bash
mkdir build-pi && cd build-pi
cmake .. \
  -DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/pi_cross \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/pi-toolchain.cmake
cmake --build . --parallel
```

There is no automated test suite — testing is manual via gameplay.

## Architecture

The project follows a strict C++ backend / QML frontend separation:

### C++ Layer (`src/`)
All C++ classes are registered as QML types in `main.cpp`:

- **`GameEngine`** (`gameengine.h/cpp`) — Central state machine with states: `Title → Betting → Dealing → TurnResult → LastThreeBetting → GameOver`. Owns the deck, manages all pharaon rules (la souche, doublets, à-contre bets, carte haute, last-three prediction), and exposes game state to QML via `Q_PROPERTY` and `Q_INVOKABLE` methods.
- **`Card`** (`gameengine.h`) — Value type representing a playing card; rank (1–13) and suit (Spades/Hearts/Diamonds/Clubs).
- **`CardModel`** (`cardmodel.h/cpp`) — `QAbstractListModel` providing the 13-rank layout for the betting table.
- **`CaseKeeper`** (`casekeeper.h/cpp`) — Tracks which cards have been revealed as gagnant/perdant/souche. QML reads this to animate the abacus beads (le tableau).
- **`PlayerModel`** (`playermodel.h/cpp`) — Simple player state (name, chips).

### QML Layer (`qml/`)
- **`Main.qml`** — Root `ApplicationWindow` (1280×800, min 960×600). Defines the global color palette, font definitions (Playfair Display, Crimson Text, JetBrains Mono), ambient film grain canvas, floating dust particles, and a `StackView` for scene navigation. Instantiates `GameEngine`.
- **`views/`** — Full-screen scenes pushed onto the `StackView`:
  - `TitleScreen.qml` — Cinematic intro with gold shimmer animation
  - `GameView.qml` — Main game table (betting, dealing, result settling)
  - `ResultsView.qml` — Final score and play-again option
- **`components/`** — Reusable UI pieces: `Card.qml` (Y-axis flip animation), `FaroTable.qml` (13-card betting grid), `DealerBox.qml` (souche/perdant/talon/gagnant positions), `CaseKeeper.qml` (le tableau — abacus beads with OutBack easing), `BettingChip.qml`, `ChipStack.qml`, `GoldText.qml` (shimmer sweep), `ParticleOverlay.qml`, `CardFan.qml`.

### QML Module
All QML files are compiled into the `Faro` URI module via `qt_add_qml_module`. Resources (PNG textures) are bundled into the executable.

## Key Design Patterns

- **Game state drives everything**: QML components bind to `GameEngine` properties and react to state changes via `Connections` blocks.
- **Signals for events**: `GameEngine` emits signals (`playerWon`, `playerLost`, `doubletOccurred`, `cardDealt`) that QML connects to for triggering animations.
- **No sound yet**: Qt Multimedia is linked but audio is marked as a future enhancement. Shader compilation for custom GLSL effects is also commented out in `CMakeLists.txt`.
- **À contre mechanic**: An à-contre bet inverts the win condition (player wins when the card is the *perdant*, not the gagnant). Internal API parameter: `bool contre`.
