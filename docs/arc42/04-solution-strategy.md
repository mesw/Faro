# 4. Solution Strategy

## Fundamental Decisions

| Goal | Decision | Rationale |
|------|----------|-----------|
| Cross-platform UI | Qt Quick / QML | Hardware-accelerated scene graph, single codebase for all target platforms including WebAssembly |
| Game logic placement | C++ (`GameEngine`) | Logic is complex (state machine, deck management, bet settlement); C++ gives type safety, testability, and performance |
| UI placement | QML only | Declarative bindings and animation system are a better fit for reactive UI than C++ widget code |
| Build system | CMake with `qt_add_qml_module` | Qt 6's recommended approach; enables QML compilation and resource bundling in one step |
| State communication | Qt property system + signals | Keeps C++ and QML loosely coupled; QML binds to properties and reacts to signals without polling |

## Architecture Style

The project follows a **layered architecture** with a strict boundary between logic and presentation:

```
┌──────────────────────────────┐
│      QML Presentation        │  Declarative UI, animations, user input
├──────────────────────────────┤
│   Qt Property / Signal Bus   │  Q_PROPERTY, Q_INVOKABLE, signals/slots
├──────────────────────────────┤
│     C++ Domain Model         │  Game rules, state machine, data models
└──────────────────────────────┘
```

The QML layer **never** contains game rule logic. The C++ layer **never** constructs UI elements.

## Key Technology Choices

- **`QAbstractListModel`** for the 13-card betting layout — integrates natively with QML `Repeater` and `ListView`
- **`StackView`** for scene navigation — provides built-in push/pop transitions between Title, Game, and Results screens
- **`Canvas`** item for the film grain overlay — procedural texture that avoids a large external asset
- **Behavior animations** on most visual properties — ensures smooth reactive changes without explicit animation controllers in C++
