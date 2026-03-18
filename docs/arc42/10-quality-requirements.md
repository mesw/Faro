# 10. Quality Requirements

## Quality Tree

```
Faro Quality
│
├── Correctness
│   └── Game rules match authentic Faro (splits, soda, coppered bets, last-three)
│
├── Visual Quality
│   ├── Animations run at 60 fps on target hardware
│   └── Atmosphere (particles, grain, vignette) is present without degrading performance
│
├── Portability
│   ├── Builds and runs on Windows, Linux, macOS without code changes
│   ├── Builds and runs as WebAssembly in a modern browser
│   └── Cross-compiles for Raspberry Pi
│
└── Maintainability
    ├── C++ and QML layers are independently modifiable
    └── Adding a new game state does not require changes to QML component internals
```

## Quality Scenarios

| ID | Scenario | Response Measure |
|----|----------|-----------------|
| Q1 | A player bets on a rank that appears as both loser and winner in the same turn | Engine detects split, awards half bet to banker; UI displays split indicator |
| Q2 | The last three cards remain; player makes a correct order prediction | Engine awards 4× the bet; ResultsView shows correct payout |
| Q3 | Application is launched on a 1920×1080 display | Window scales correctly; minimum 960×600 enforced by `ApplicationWindow` |
| Q4 | Application is compiled for WebAssembly and loaded in Chrome | Game plays identically to desktop; no rule differences |
| Q5 | A developer adds a new game state to `GameEngine` | Only `GameEngine` and `GameView` require changes; other QML components are unaffected |
