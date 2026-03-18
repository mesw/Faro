# 12. Glossary

## Domain Terms (Faro)

| Term | Definition |
|------|------------|
| **Faro bank** | A game of faro; also the establishment or banker running the game |
| **Punter** | A player (bettor) in a faro game; any number may participate simultaneously |
| **Check** | A betting chip purchased from the banker; typical US values were 50 cents to $10 |
| **Dealing box** | A mechanical device (also called a "shoe") that holds the shuffled deck and controls card draws to prevent manipulation |
| **Soda** | The first card in the dealing box; it is "burned off" (removed without effect) once at the start of the game, leaving 51 cards in play |
| **Banker's card** | The first card drawn each turn, placed to the right of the dealing box; all bets on that rank are lost by punters (also informally called the "loser") |
| **Player's card** | The second card drawn each turn, placed to the left of the dealing box; all bets on that rank pay 1:1 (also called "carte anglaise" or informally "winner") |
| **Doublet** | When the banker's card and player's card share the same rank; the banker wins half the stakes on that denomination (also called a "split") |
| **Copper** | A hexagonal (6-sided) token placed on a bet to reverse it; the punter then wins if the card is the banker's card rather than the player's card. A penny was sometimes used in place of a copper token |
| **Coppering** | The act of placing a copper token on a bet to reverse its win/loss condition |
| **High card bet** | A bet placed on the "high card" bar at the top of the layout; wins if the player's card has a higher rank than the banker's card |
| **Call the turn** | The final bet of the game, placed when exactly three cards remain in the dealing box; the punter predicts the exact order in which the three cards will be drawn |
| **Hock** | The last card remaining in the dealing box after the call-the-turn draw; it plays no further role |
| **Cat-hop** | A call-the-turn situation where two of the three remaining cards share the same rank; the odds drop from 5:1 to 2:1, and the payout is 1:1 instead of 4:1 |
| **Case keeper** | An abacus-style device with one spindle per denomination and four counters per spindle; as each card is played (winning or losing), one counter is moved to track which cards remain in the dealing box |
| **Turn** | One deal cycle: one banker's card and one player's card are drawn and settled. A full game yields 24 turns (51 active cards dealt in pairs), followed by the call the turn |

## Technical Terms

| Term | Definition |
|------|------------|
| **QML** | Qt Modeling Language — a declarative UI language used for all visual components in this project |
| **Qt Quick** | The Qt framework for QML-based UIs, backed by a hardware-accelerated scene graph |
| **`Q_PROPERTY`** | Qt macro that exposes a C++ member variable to the QML engine with optional change notifications |
| **`Q_INVOKABLE`** | Qt macro that makes a C++ method callable from QML |
| **`QAbstractListModel`** | Qt base class for list data models that integrate natively with QML `Repeater` and `ListView` |
| **`StackView`** | Qt Quick Controls component managing a navigation stack of full-screen views with push/pop transitions |
| **`Behavior`** | QML element that automatically animates any change to a target property |
| **ASYNCIFY** | Emscripten transform that allows synchronous-style C++ code to run in the asynchronous WebAssembly environment |
| **`qt_add_qml_module`** | CMake function that compiles QML files and embeds resources into the executable as a named module |
