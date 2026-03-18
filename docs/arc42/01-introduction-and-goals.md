# 1. Introduction and Goals

## Requirements Overview

Faro is an interactive recreation of *pharaon*, the late 17th-century French gambling card game that originated during the reign of Louis XIV and later spread across Europe and to the United States. The application implements authentic Faro rules and serves as a demonstration of Qt 6 capabilities.

**Core functional requirements:**

- Implement full Faro rules: soda burn, banker's card / player's card dealing, doublets (splits), coppering, high card bets, and call the turn
- Provide an abacus-style case keeper tracking which cards have been played as banker's or player's card
- Support one or more punters betting against a banker across 24 turns plus a final call-the-turn bet
- Present a visually rich period-appropriate experience with animations and atmospheric effects

## Quality Goals

| Priority | Quality Goal | Motivation |
|----------|-------------|------------|
| 1 | **Visual fidelity** | The application exists partly as a Qt Quick showcase; animations and effects must be smooth and polished |
| 2 | **Rule correctness** | Faro rules must be faithfully implemented including edge cases (splits, soda, last-three) |
| 3 | **Cross-platform portability** | Must build and run on Windows, Linux, macOS, WebAssembly, and Raspberry Pi |
| 4 | **Maintainability** | Clean C++/QML separation so game logic and UI can evolve independently |

## Stakeholders

| Role | Expectation |
|------|-------------|
| Player | An engaging, visually appealing implementation of Faro with correct rules |
| Qt developer / learner | A reference showing how to integrate C++ logic with QML, implement animations, and structure a Qt Quick project |
