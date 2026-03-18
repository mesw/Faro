# 2. Architecture Constraints

## Technical Constraints

| Constraint | Rationale |
|------------|-----------|
| Qt 6.8.3 | Minimum version required for `qt_standard_project_setup` and the QML module system used |
| C++17 | Required by Qt 6 and used throughout the codebase |
| CMake 3.16+ | Qt 6's recommended build system; no qmake `.pro` file is provided |
| QML-only UI | All visual components must be written in QML/Qt Quick; no Qt Widgets |
| GPL-3.0 license | Any modifications or derivatives must be released under the same license |

## Organizational Constraints

| Constraint | Rationale |
|------------|-----------|
| No external game libraries | Game logic is implemented from scratch in C++; no third-party game engines or card-game frameworks |
| No backend / network layer | Faro is a single-player, offline desktop application |
| No automated test suite | Testing is performed manually by playing the game |

## Platform Constraints

| Platform | Constraint |
|----------|------------|
| WebAssembly | Requires Emscripten with ASYNCIFY enabled; 128 MB memory limit applies |
| Raspberry Pi | Requires a cross-compilation toolchain and a Qt 6 build targeting ARM |
