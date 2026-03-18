# 6. Runtime View

## Scenario 1: Application Startup

```
main.cpp
  │
  ├─ create QGuiApplication
  ├─ register QML types (GameEngine, CardModel, PlayerModel, CaseKeeper, Card)
  ├─ create QQmlApplicationEngine
  └─ load qml/Main.qml
       │
       ├─ instantiate GameEngine (state = Title)
       ├─ start ambient effects (particles, grain canvas)
       └─ StackView.push(TitleScreen)
```

## Scenario 2: Starting a New Game

```
Player clicks "Deal Me In" on TitleScreen
  │
  └─ TitleScreen emits signal → Main.qml
       │
       └─ GameEngine.startNewGame(startingChips)
            │
            ├─ shuffle deck
            ├─ burn soda card (first card removed from play, no bets affected)
            │    → 51 cards remain active for 24 turns + call the turn
            ├─ gameState = Betting
            └─ gameStateChanged signal
                 │
                 └─ StackView.push(GameView)
```

## Scenario 3: Placing Bets and Dealing a Turn

```
Player clicks a card on FaroTable
  │
  └─ GameView calls GameEngine.placeBet(rank, amount, coppered)
       │
       └─ GameEngine updates internal bet map → betChanged signal → GameView updates chip display

Player clicks "Deal"
  │
  └─ GameView calls GameEngine.confirmBets()
       │
       └─ GameEngine.dealTurn()
            │
            ├─ draw banker's card (placed right) → cardDealt signal → DealerBox animates flip
            │    all bets on this rank are lost by punters
            ├─ draw player's card (placed left)  → cardDealt signal → DealerBox animates flip
            │    all bets on this rank pay 1:1
            ├─ detect doublet? (same rank) → banker takes half stakes (splitOccurred signal)
            ├─ settle all bets (playerWon / playerLost signals)
            ├─ record both cards in CaseKeeper → shownCountChanged → CaseKeeper.qml moves beads
            └─ gameState = TurnResult → GameView shows result overlay
```

## Scenario 4: Call the Turn (Last Three Prediction)

```
After turn 24, exactly 3 cards remain in the dealing box
  │
  └─ GameEngine.gameState = LastThreeBetting
       │
       └─ GameView shows call-the-turn prediction UI

Engine checks remaining cards:
  ├─ All three the same rank? → no bet possible, skip to GameOver
  ├─ Two of three share a rank? → cat-hop: odds 2:1, payout 1:1
  └─ All different ranks?     → normal: odds 5:1, payout 4:1

Player selects predicted order (banker's card, player's card, hock) and confirms
  │
  └─ GameEngine.placeLastThreeBet(first, second, third, amount)
       │
       ├─ reveal cards one by one
       ├─ compare prediction → award at correct odds or nothing
       └─ gameState = GameOver → StackView.push(ResultsView)
```
