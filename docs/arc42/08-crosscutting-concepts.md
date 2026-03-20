# 8. Cross-cutting Concepts

## C++/QML Integration Pattern

All C++ classes exposed to QML follow this pattern:

1. Inherit from `QObject`
2. Expose data via `Q_PROPERTY` with `NOTIFY` signals
3. Expose actions via `Q_INVOKABLE` methods
4. Register with `qmlRegisterType<T>()` in `main.cpp`

QML components bind declaratively to properties and call invokable methods directly. C++ never holds references to QML objects.

## Animation Strategy

Animations are applied at three levels:

| Level | Mechanism | Example |
|-------|-----------|---------|
| Property changes | `Behavior on <property>` | Chip count fading in/out |
| Triggered sequences | `SequentialAnimation` + `ScriptAction` | Card flip (Y-axis rotation in two steps) |
| Ambient loops | `NumberAnimation` with `loops: Animation.Infinite` | Dust particles, film grain repaints |

## Visual Design System

Defined once in `Main.qml` and referenced throughout:

```qml
// Color palette
property color feltGreen:   "#2d5a27"
property color goldAccent:  "#c9a84c"
property color copperColor: "#b87333"
property color ivoryWhite:  "#f5f0e8"

// Font families
property string serifFont:  "Playfair Display"
property string bodyFont:   "Crimson Text"
property string monoFont:   "JetBrains Mono"
```

Components reference these via the root window's property aliases — no hardcoded colors in individual components.

## Resource Management

All assets are compiled into the executable via `qt_add_qml_module RESOURCES`. The QML URI is `Faro` (version 1.0). Components import each other with relative paths inside the module; no absolute `qrc:/` paths are used in QML code.

## WebAssembly Performance

The browser build applies several optimisations to keep tab memory below 200 MB and animations smooth under the single-threaded WASM event loop:

- **Platform detection**: `Qt.platform.os === "wasm"` (exposed as `root.isWasm`) gates all WASM-specific behaviour.
- **Film grain**: disabled entirely on WASM (timer `running: false`); on desktop the repaint interval is 400 ms and the `ImageData` buffer is cached and reused across frames to avoid per-frame heap allocation.
- **Dust particles**: capped at 8 on WASM, 30 on desktop.
- **Object pooling**: `FlyingCard` and `FlyingChip` instances are pre-allocated into pools (`_cardPool`, `_chipPool`) in `GameView.qml` using inline `Component` declarations. Signal handlers acquire a free item from the pool and mark it `visible = true` instead of calling `Qt.createComponent` per event. Items return to the pool by setting `visible = false` when their animation finishes, avoiding GC pressure in the single-threaded runtime.
- **GPU layer compositing**: `layer.enabled` / `layer.effect` removed from `BettingChip.qml` — no separate render surface per chip.
- **AI bet filtering**: `engine.aiBetsForRank(rank)` (C++ `Q_INVOKABLE`) replaces a JS `.filter()` inside each of the 13 card-slot delegates, eliminating per-slot intermediate array allocations on every `allPlayerBets` change.

## Error Handling

The application has no network, file I/O, or external dependencies at runtime, so error handling is minimal. Invalid game states are prevented by disabling UI controls in QML based on `GameEngine.gameState`. Bet placement (`placeBet`, `removeBet`, `placeHighCardBet`) is no longer gated by `bettingPhase` or `bettingLocked` — bets are accepted in any state except `GameOver`; dead-card protection remains in the `isDead` guard in `FaroTable.qml`.
