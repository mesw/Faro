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

## Error Handling

The application has no network, file I/O, or external dependencies at runtime, so error handling is minimal. Invalid game states are prevented by disabling UI controls in QML based on `GameEngine.gameState`.
