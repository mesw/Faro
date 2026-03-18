# 3. System Scope and Context

## Business Context

Faro is a self-contained desktop application. It has no external system interfaces.

```
┌─────────────────────────────────────────┐
│                                         │
│                  Faro                   │
│         (Qt Quick Application)          │
│                                         │
│  ┌─────────┐        ┌───────────────┐   │
│  │ Player  │◄──────►│  Game Engine  │   │
│  │ (human) │        │  (C++ logic)  │   │
│  └─────────┘        └───────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**External interfaces:** None. The application does not communicate with any external services, databases, or APIs.

**User interaction:** A single human player interacts via mouse/touch with the QML UI.

## Technical Context

```
┌──────────────────────────────────────────────────────┐
│                    FaroGame process                  │
│                                                      │
│  ┌────────────────┐       ┌────────────────────────┐ │
│  │  QML Engine    │◄─────►│   C++ Objects          │ │
│  │  (Qt Quick     │       │   (GameEngine,         │ │
│  │   scene graph) │       │    CardModel,          │ │
│  │                │       │    CaseKeeper,         │ │
│  │  Main.qml      │       │    PlayerModel)        │ │
│  │  views/        │       └────────────────────────┘ │
│  │  components/   │                                  │
│  └────────────────┘                                  │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │  Qt 6.8 Runtime                              │    │
│  │  Core · GUI · Quick · QuickControls2         │    │
│  │  Multimedia (linked, unused)                 │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘
         │
         ▼
  OS windowing / GPU / audio subsystem
```

The QML engine and C++ objects communicate via Qt's property system, signals/slots, and `Q_INVOKABLE` method calls. All resources (QML files, PNG textures) are compiled into the executable via `qt_add_qml_module`.
