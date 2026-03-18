# 9. Architecture Decisions

## ADR-001: Qt Quick (QML) instead of Qt Widgets

**Status:** Accepted

**Context:** The application needs rich animations, custom visual components, and WebAssembly support.

**Decision:** Use Qt Quick / QML for all UI code. No Qt Widgets.

**Consequences:** The scene graph provides hardware-accelerated rendering and native WebAssembly support. The trade-off is that standard desktop controls require `Qt Quick Controls 2` rather than native-looking widgets.

---

## ADR-002: Game logic in C++, not QML

**Status:** Accepted

**Context:** Faro rules are complex (split detection, bet settlement, last-three ordering). Logic could be written in QML/JavaScript.

**Decision:** All game rules and state live in `GameEngine` (C++). QML only handles presentation.

**Consequences:** Logic is strongly typed, easier to reason about, and could be unit-tested independently of the UI. QML files remain declarative and short.

---

## ADR-003: Single executable with embedded resources

**Status:** Accepted

**Context:** The application needs to run on multiple platforms including WebAssembly where a separate asset directory is impractical.

**Decision:** Use `qt_add_qml_module` to compile all QML files and `RESOURCES` to embed textures into the binary.

**Consequences:** Deployment is a single file. The trade-off is that assets cannot be updated without recompiling.

---

## ADR-004: No automated test suite

**Status:** Accepted (to revisit)

**Context:** The project is currently a showcase/demo application.

**Decision:** Testing is performed manually by playing through the game. No unit or integration test framework has been set up.

**Consequences:** Regressions in game logic are caught manually. If the project grows, adding a C++ test harness (e.g. Qt Test or Catch2) for `GameEngine` would be a priority.

---

## ADR-005: Qt Multimedia linked but unused

**Status:** Pending

**Context:** Sound effects (dealing cards, winning chips) would enhance the period atmosphere.

**Decision:** `Qt6::Multimedia` is linked in `CMakeLists.txt` as a placeholder for future audio integration.

**Consequences:** No current functionality. When audio is added, the infrastructure is already in place.
