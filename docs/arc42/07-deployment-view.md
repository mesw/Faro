# 7. Deployment View

## Desktop (Windows / Linux / macOS)

```
┌───────────────────────────────────┐
│  Host OS                          │
│                                   │
│  ┌─────────────────────────────┐  │
│  │  FaroGame executable        │  │
│  │  (all QML + resources       │  │
│  │   compiled in)              │  │
│  └─────────────────────────────┘  │
│                                   │
│  ┌─────────────────────────────┐  │
│  │  Qt 6.8 runtime DLLs / SOs  │  │
│  │  (deployed alongside or     │  │
│  │   system-installed)         │  │
│  └─────────────────────────────┘  │
└───────────────────────────────────┘
```

Build artifact: `FaroGame` (or `FaroGame.exe` on Windows). All QML files and PNG textures are embedded in the binary via `qt_add_qml_module` — no separate asset directory is needed at runtime.

## WebAssembly

```
┌─────────────────────────────────────────┐
│  Web Server                             │
│                                         │
│  FaroGame.html                          │
│  FaroGame.js       (Emscripten runtime) │
│  FaroGame.wasm     (compiled binary)    │
│  FaroGame.data     (Qt resources)       │
└─────────────────────────────────────────┘
         │  HTTP
         ▼
┌─────────────────────┐
│  Browser + WASM VM  │
└─────────────────────┘
```

Constraints: ASYNCIFY enabled, 256 MB initial heap + `ALLOW_MEMORY_GROWTH=1` (heap grows on demand beyond 256 MB). Ambient effects are disabled on WASM at runtime via `Qt.platform.os === "wasm"`: film grain is turned off and dust particles are capped at 8 (vs. 30 on desktop). Serve with any static file server (e.g. `python3 -m http.server 8080`).

## Raspberry Pi

Cross-compiled on a desktop host using a Pi sysroot and ARM toolchain. The resulting binary and Qt runtime are deployed to the device. A display server (e.g. EGLFS or X11) must be available on the Pi.
