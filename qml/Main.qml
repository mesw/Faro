import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Faro.Engine 1.0

ApplicationWindow {
    id: root
    width: 1280; height: 800
    minimumWidth: 960; minimumHeight: 600
    visible: true
    title: "Pharaon — Un Jeu de la Cour de France"
    color: "#0a0608"

    // ── Palette ──
    readonly property color feltGreen:   "#1e4d2c"
    readonly property color feltDark:    "#102a18"
    readonly property color goldAccent:  "#c9a227"
    readonly property color goldBright:  "#e8c84a"
    readonly property color goldDim:     "#7a5f1e"
    readonly property color copperAccent:"#c07838"
    readonly property color ivoryWhite:  "#f0e6cc"
    readonly property color cardWhite:   "#f5edd8"
    readonly property color cardRed:     "#8c1515"
    readonly property color shadowBlack: "#08060a"
    readonly property color winGreen:    "#4a9958"

    // ── Fonts ──
    readonly property string displayFont: "'Playfair Display', 'Georgia', serif"
    readonly property string bodyFont:    "'Crimson Text', 'Times New Roman', serif"
    readonly property string monoFont:    "'JetBrains Mono', 'Courier New', monospace"

    // ── Platform detection ──
    readonly property bool isWasm: Qt.platform.os === "wasm"

    // ── Game Engine ──
    GameEngine { id: gameEngine }

    // ── Background ──
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1c0e14" }
            GradientStop { position: 0.35; color: "#120a0e" }
            GradientStop { position: 1.0; color: "#0a0608" }
        }
    }

    // Film grain
    Canvas {
        id: grainCanvas; anchors.fill: parent; opacity: 0.04; z: 100
        property int frame: 0
        property var cachedImageData: null
        Timer {
            interval: root.isWasm ? 0 : 400
            running: !root.isWasm
            repeat: true
            onTriggered: { grainCanvas.frame++; grainCanvas.requestPaint() }
        }
        onPaint: {
            var ctx = getContext("2d"); var w = width; var h = height
            ctx.clearRect(0, 0, w, h)
            if (!cachedImageData || cachedImageData.width !== w)
                cachedImageData = ctx.createImageData(w, h)
            var imgData = cachedImageData
            for (var i = 0; i < imgData.data.length; i += 16) {
                var v = Math.random() * 255
                imgData.data[i] = v; imgData.data[i+1] = v; imgData.data[i+2] = v; imgData.data[i+3] = 40
            }
            ctx.putImageData(imgData, 0, 0)
        }
    }

    // Dust particles
    Repeater {
        model: root.isWasm ? 8 : 30
        Rectangle {
            id: dustParticle
            readonly property real startX: Math.random() * root.width
            readonly property real startY: Math.random() * root.height
            readonly property real drift:  20 + Math.random() * 60
            readonly property int  dur:    6000 + Math.random() * 12000
            x: startX; y: startY
            width: 1 + Math.random() * 3; height: width; radius: width / 2
            color: root.goldAccent; opacity: 0.0; z: 50
            SequentialAnimation on opacity { loops: Animation.Infinite
                PauseAnimation { duration: dustParticle.dur * Math.random() }
                NumberAnimation { to: 0.15 + Math.random() * 0.2; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.0; duration: 3000; easing.type: Easing.InOutSine }
            }
            NumberAnimation on y { loops: Animation.Infinite; from: dustParticle.startY; to: dustParticle.startY - dustParticle.drift; duration: dustParticle.dur; easing.type: Easing.InOutSine }
            NumberAnimation on x { loops: Animation.Infinite; from: dustParticle.startX - 10; to: dustParticle.startX + 10; duration: dustParticle.dur * 0.7; easing.type: Easing.InOutSine }
        }
    }

    // Vignette
    Canvas {
        anchors.fill: parent; z: 90
        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
            var cx = width/2, cy = height/2
            var r0 = Math.max(width, height) * 0.385
            var r1 = Math.max(width, height) * 0.8
            var grad = ctx.createRadialGradient(cx, cy, r0, cx, cy, r1)
            grad.addColorStop(0.0, "transparent"); grad.addColorStop(1.0, "#cc000000")
            ctx.fillStyle = grad; ctx.fillRect(0, 0, width, height)
        }
    }

    // ── View Stack ────────────────────────────────────────────────────────────
    StackView {
        id: viewStack; anchors.fill: parent; z: 10; initialItem: titleScreen

        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
            PropertyAnimation { property: "scale";   from: 0.95; to: 1.0; duration: 600; easing.type: Easing.OutCubic }
        }
        pushExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 400; easing.type: Easing.InCubic }
        }
        popEnter:  Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 400 } }
        popExit:   Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 400 } }
    }

    Component {
        id: titleScreen
        TitleScreen {
            onStartGame: {
                gameEngine.startNewGame(AppSettings.startingChips, AppSettings.aiPlayerCount)
                viewStack.push(gameView)
            }
            onOpenSettings: {
                viewStack.push(settingsView)
            }
            onOpenMultiplayer: {
                if (AppSettings.serverUrl !== "") {
                    gameEngine.startNewGame(AppSettings.startingChips, 0)
                    viewStack.push(gameView)
                }
            }
        }
    }

    Component {
        id: settingsView
        SettingsView {
            onBackToTitle: viewStack.pop()
        }
    }

    Component {
        id: gameView
        GameView {
            engine: gameEngine
            onGameFinished: {
                viewStack.push(resultsView)
            }
            onBackToTitle: {
                viewStack.pop(null)
            }
        }
    }

    Component {
        id: resultsView
        ResultsView {
            engine: gameEngine
            onPlayAgain: {
                if (engine.bankBrokenState) {
                    engine.startNewRound()
                    viewStack.pop()
                } else {
                    gameEngine.startNewGame(gameEngine.playerChips, AppSettings.aiPlayerCount)
                    viewStack.pop()
                }
            }
            onBackToTitle: {
                viewStack.pop(null)
            }
        }
    }
}
