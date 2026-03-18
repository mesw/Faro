# 11. Risks and Technical Debt

## Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Qt 6.8 API changes break the build on a future Qt version | Low | Medium | Pin Qt version in CI; review Qt changelog before upgrading |
| R2 | WebAssembly memory limit (128 MB) is exceeded as the app grows | Low | High | Profile wasm build; increase `TOTAL_MEMORY` if needed |
| R3 | Game rule bugs go undetected without an automated test suite | Medium | Medium | Add Qt Test or Catch2 unit tests for `GameEngine` (see ADR-004) |

## Technical Debt

| ID | Item | Location | Impact |
|----|------|----------|--------|
| TD1 | No automated tests for game logic | `src/gameengine.cpp` | Regressions are only caught by manual play |
| TD2 | Sound effects not implemented | `CMakeLists.txt`, Qt Multimedia linked | Dead dependency; audio stubs need to be filled in |
| TD3 | Shader pipeline commented out | `CMakeLists.txt` lines 56–63 | Custom GLSL effects (`felt.frag`, `glow.frag`, `vignette.frag`) are planned but not present |
| TD4 | Texture files are placeholder stubs (73–74 bytes each) | `resources/*.png` | Real textures would improve visual fidelity |
| TD5 | Global color palette and fonts defined only in `Main.qml` | `qml/Main.qml` | Child components access them via parent traversal; a dedicated style singleton would be more robust |
