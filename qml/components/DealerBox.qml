import QtQuick
import QtQuick.Controls
import Faro.Engine 1.0

Item {
    id: dealerBoxRoot

    required property GameEngine engine

    // Slot IDs for coordinate mapping (used by GameView for FlyingCard animation)
    readonly property alias loserSlot:  loserSlotItem
    readonly property alias winnerSlot: winnerSlotItem
    readonly property alias talonSlot:  talonSlotItem

    Row {
        anchors.centerIn: parent
        spacing: 20

        // ── SOUCHE ────────────────────────────────────────────────────────────
        Column {
            spacing: 4
            opacity: engine.sodaCard ? 1 : 0.3

            HoverHandler { id: soucheHover }
            ToolTip { visible: soucheHover.hovered; delay: 600
                text: "The first card dealt from the deck — bets on this rank are void for the game" }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SOUCHE"
                font.family: root.bodyFont; font.pixelSize: 10; font.letterSpacing: 2
                color: root.goldDim
            }

            Card {
                width: 70; height: 100
                rank: engine.sodaCard ? engine.sodaCard.rank : 1
                suit: engine.sodaCard ? engine.sodaCard.suit : 0
                faceUp: engine.sodaCard !== null
                opacity: 0.6
            }
        }

        // ── PERDANT ───────────────────────────────────────────────────────────
        Column {
            spacing: 4

            HoverHandler { id: perdantHover }
            ToolTip { visible: perdantHover.hovered; delay: 600
                text: "The first card of each pair — bets on this rank lose" }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PERDANT"
                font.family: root.bodyFont; font.pixelSize: 10; font.letterSpacing: 2
                color: root.cardRed
            }

            Item {
                id: loserSlotItem
                width: 70; height: 100

                Rectangle {
                    anchors.fill: parent; radius: 6
                    color: "transparent"
                    border.color: root.cardRed; border.width: 1; opacity: 0.3
                    visible: !engine.loserCard
                }

                Card {
                    id: loserCardVisual
                    anchors.fill: parent
                    rank: engine.loserCard ? engine.loserCard.rank : 1
                    suit: engine.loserCard ? engine.loserCard.suit : 0
                    faceUp: engine.loserCard !== null
                    visible: engine.loserCard !== null
                    opacity: 0

                    Connections {
                        target: engine
                        function onCardDealt(cardRank, cardSuit, isWinner) {
                            if (!isWinner) {
                                loserCardVisual.opacity = 0
                                loserRevealAnim.restart()
                            }
                        }
                    }

                    // Wait for FlyingCard to land (950 ms), then fade in and stay visible
                    SequentialAnimation {
                        id: loserRevealAnim
                        PauseAnimation  { duration: 950 }
                        NumberAnimation { target: loserCardVisual; property: "opacity"; to: 1; duration: 150 }
                    }
                }

                // Red glow
                Rectangle {
                    anchors.fill: parent; anchors.margins: -4; radius: 10
                    color: "transparent"; border.color: root.cardRed; border.width: 2
                    opacity: engine.loserCard ? 0.4 : 0
                    visible: engine.gameState === GameEngine.TurnResult
                    SequentialAnimation on opacity {
                        loops: 3
                        running: engine.gameState === GameEngine.TurnResult && engine.loserCard !== null
                        NumberAnimation { to: 0.6; duration: 300 }
                        NumberAnimation { to: 0.2; duration: 300 }
                    }
                }
            }
        }

        // ── TALON ─────────────────────────────────────────────────────────────
        Column {
            spacing: 4

            HoverHandler { id: talonHover }
            ToolTip { visible: talonHover.hovered; delay: 600
                text: "The remaining undealt cards in the deck" }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TALON"
                font.family: root.bodyFont; font.pixelSize: 10; font.letterSpacing: 2
                color: root.goldDim
            }

            Item {
                id: talonSlotItem
                width: 70; height: 100

                Repeater {
                    model: Math.min(engine.cardsRemaining, 5)
                    Card {
                        x: -index * 0.5; y: -index * 0.5
                        width: 70; height: 100
                        rank: 1; suit: 0; faceUp: false
                    }
                }
            }
        }

        // ── GAGNANT ───────────────────────────────────────────────────────────
        Column {
            spacing: 4

            HoverHandler { id: gagnantHover }
            ToolTip { visible: gagnantHover.hovered; delay: 600
                text: "The second card of each pair — bets on this rank win" }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "GAGNANT"
                font.family: root.bodyFont; font.pixelSize: 10; font.letterSpacing: 2
                color: root.winGreen
            }

            Item {
                id: winnerSlotItem
                width: 70; height: 100

                Rectangle {
                    anchors.fill: parent; radius: 6
                    color: "transparent"
                    border.color: root.winGreen; border.width: 1; opacity: 0.3
                    visible: !engine.winnerCard
                }

                Card {
                    id: winnerCardVisual
                    anchors.fill: parent
                    rank: engine.winnerCard ? engine.winnerCard.rank : 1
                    suit: engine.winnerCard ? engine.winnerCard.suit : 0
                    faceUp: engine.winnerCard !== null
                    visible: engine.winnerCard !== null
                    opacity: 0

                    Connections {
                        target: engine
                        function onCardDealt(cardRank, cardSuit, isWinner) {
                            if (isWinner) {
                                winnerCardVisual.opacity = 0
                                winnerRevealAnim.restart()
                            }
                        }
                    }

                    // Wait for FlyingCard to land (950 ms), then fade in and stay visible
                    SequentialAnimation {
                        id: winnerRevealAnim
                        PauseAnimation  { duration: 950 }
                        NumberAnimation { target: winnerCardVisual; property: "opacity"; to: 1; duration: 150 }
                    }
                }

                // Green glow
                Rectangle {
                    anchors.fill: parent; anchors.margins: -4; radius: 10
                    color: "transparent"; border.color: root.winGreen; border.width: 2
                    opacity: engine.winnerCard ? 0.4 : 0
                    visible: engine.gameState === GameEngine.TurnResult
                    SequentialAnimation on opacity {
                        loops: 3
                        running: engine.gameState === GameEngine.TurnResult && engine.winnerCard !== null
                        NumberAnimation { to: 0.6; duration: 300 }
                        NumberAnimation { to: 0.2; duration: 300 }
                    }
                }
            }
        }
    }

    // ── Doublet indicator ─────────────────────────────────────────────────────
    Rectangle {
        anchors.top: parent.bottom; anchors.topMargin: -8
        anchors.horizontalCenter: parent.horizontalCenter
        width: splitText.width + 24; height: 28; radius: 14
        color: root.copperAccent
        visible: engine.loserCard && engine.winnerCard &&
                 engine.loserCard.rank === engine.winnerCard.rank
        opacity: 0

        HoverHandler { id: doubletHover }
        ToolTip { visible: doubletHover.hovered; delay: 600
            text: "Both cards share the same rank — the banker takes half of all bets on this rank" }

        NumberAnimation on opacity {
            from: 0; to: 1; duration: 400
            running: engine.loserCard && engine.winnerCard &&
                     engine.loserCard.rank === engine.winnerCard.rank
        }

        Text {
            id: splitText
            anchors.centerIn: parent
            text: "✦ DOUBLET ✦"
            font.family: root.bodyFont; font.pixelSize: 12; font.letterSpacing: 2; font.bold: true
            color: root.shadowBlack
        }
    }
}
