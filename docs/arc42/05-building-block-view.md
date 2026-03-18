# 5. Building Block View

## Level 1 — Overall System

```
┌─────────────────────────────────────────────────────┐
│                    FaroGame                         │
│                                                     │
│  ┌──────────────┐          ┌─────────────────────┐  │
│  │  C++ Domain  │◄────────►│    QML Presentation │  │
│  │    Layer     │          │        Layer         │  │
│  └──────────────┘          └─────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Level 2 — C++ Domain Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| `GameEngine` | `src/gameengine.h/cpp` | Central state machine; owns deck, bets, turn logic, and all Faro rules |
| `Card` | `src/gameengine.h` | Value type for a playing card (rank 1–13, suit, face-up state) |
| `CardModel` | `src/cardmodel.h/cpp` | `QAbstractListModel` exposing the 13-rank layout for QML `Repeater` |
| `CaseKeeper` | `src/casekeeper.h/cpp` | Tracks cards revealed as winner/loser/soda; queried by QML for abacus display |
| `PlayerModel` | `src/playermodel.h/cpp` | Simple player state (name, chip count) |

### GameEngine State Machine

```
Title ──startNewGame()──► Betting ──confirmBets()──► Dealing
                             ▲                           │
                             │                      dealTurn()
                         nextBettingRound()              │
                             │                           ▼
                         TurnResult ◄── settle ── TurnResult
                             │
                    (after turn 24)
                             │
                             ▼
                     LastThreeBetting ──placeLastThreeBet()──► GameOver
```

## Level 2 — QML Presentation Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| `Main.qml` | `qml/Main.qml` | Root window; global palette, fonts, ambient effects, `StackView` host |
| `TitleScreen` | `qml/views/TitleScreen.qml` | Cinematic entry screen |
| `GameView` | `qml/views/GameView.qml` | Main game table: betting controls, deal button, results |
| `ResultsView` | `qml/views/ResultsView.qml` | End-of-game summary |
| `Card` | `qml/components/Card.qml` | Playing card visual with Y-axis flip animation |
| `FaroTable` | `qml/components/FaroTable.qml` | 13-card betting grid |
| `DealerBox` | `qml/components/DealerBox.qml` | Soda / Loser / Deck / Winner card positions |
| `CaseKeeper` | `qml/components/CaseKeeper.qml` | Abacus bead tracker (spring-loaded OutBack easing) |
| `BettingChip` | `qml/components/BettingChip.qml` | Individual chip with copper-penny toggle |
| `ChipStack` | `qml/components/ChipStack.qml` | Stacked chip visual for larger amounts |
| `GoldText` | `qml/components/GoldText.qml` | Shimmer sweep text effect |
| `ParticleOverlay` | `qml/components/ParticleOverlay.qml` | 30 ambient floating dust motes |
| `CardFan` | `qml/components/CardFan.qml` | Decorative fanned card display |
