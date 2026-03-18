import QtQuick
import QtQuick.Controls
import Faro.Engine 1.0

Item {
    id: dealerBoxRoot

    required property GameEngine engine

    Row {
        anchors.centerIn: parent
        spacing: 20

        // Soda card
        Column {
            spacing: 4
            opacity: engine.sodaCard ? 1 : 0.3

            HoverHandler { id: soucheHover }
            ToolTip {
                visible: soucheHover.hovered
                text: "The first card dealt from the deck — bets on this rank are void for the game"
                delay: 600
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SOUCHE"
                font.family: root.bodyFont
                font.pixelSize: 10
                font.letterSpacing: 2
                color: root.goldDim
            }

            Card {
                id: sodaCardVisual
                width: 70
                height: 100
                rank: engine.sodaCard ? engine.sodaCard.rank : 1
                suit: engine.sodaCard ? engine.sodaCard.suit : 0
                faceUp: engine.sodaCard !== null
                opacity: 0.6
            }
        }

        // Discard / loser pile
        Column {
            spacing: 4

            HoverHandler { id: perdantHover }
            ToolTip {
                visible: perdantHover.hovered
                text: "The first card of each pair — bets on this rank lose"
                delay: 600
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PERDANT"
                font.family: root.bodyFont
                font.pixelSize: 10
                font.letterSpacing: 2
                color: root.cardRed
            }

            Item {
                width: 70; height: 100

                // Empty slot indicator
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: "transparent"
                    border.color: root.cardRed
                    border.width: 1
                    opacity: 0.3
                    visible: !engine.loserCard
                }

                Card {
                    id: loserCardVisual
                    anchors.fill: parent
                    rank: engine.loserCard ? engine.loserCard.rank : 1
                    suit: engine.loserCard ? engine.loserCard.suit : 0
                    faceUp: engine.loserCard !== null
                    visible: engine.loserCard !== null

                    // Slide-in animation
                    x: 0
                    Behavior on visible {
                        SequentialAnimation {
                            PropertyAction { target: loserCardVisual; property: "x"; value: -80 }
                            PropertyAction { target: loserCardVisual; property: "opacity"; value: 0 }
                            NumberAnimation { target: loserCardVisual; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
                            NumberAnimation { target: loserCardVisual; property: "opacity"; to: 1; duration: 200 }
                        }
                    }
                }

                // Red glow for loser
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 10
                    color: "transparent"
                    border.color: root.cardRed
                    border.width: 2
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

        // Deck (remaining cards)
        Column {
            spacing: 4

            HoverHandler { id: talonHover }
            ToolTip {
                visible: talonHover.hovered
                text: "The remaining undealt cards in the deck"
                delay: 600
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TALON"
                font.family: root.bodyFont
                font.pixelSize: 10
                font.letterSpacing: 2
                color: root.goldDim
            }

            Item {
                width: 70; height: 100

                // Stacked deck visual
                Repeater {
                    model: Math.min(engine.cardsRemaining, 5)
                    Card {
                        x: -index * 0.5
                        y: -index * 0.5
                        width: 70; height: 100
                        rank: 1; suit: 0
                        faceUp: false
                    }
                }
            }
        }

        // Winner card
        Column {
            spacing: 4

            HoverHandler { id: gagnantHover }
            ToolTip {
                visible: gagnantHover.hovered
                text: "The second card of each pair — bets on this rank win"
                delay: 600
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "GAGNANT"
                font.family: root.bodyFont
                font.pixelSize: 10
                font.letterSpacing: 2
                color: root.winGreen
            }

            Item {
                width: 70; height: 100

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: "transparent"
                    border.color: root.winGreen
                    border.width: 1
                    opacity: 0.3
                    visible: !engine.winnerCard
                }

                Card {
                    id: winnerCardVisual
                    anchors.fill: parent
                    rank: engine.winnerCard ? engine.winnerCard.rank : 1
                    suit: engine.winnerCard ? engine.winnerCard.suit : 0
                    faceUp: engine.winnerCard !== null
                    visible: engine.winnerCard !== null

                    Behavior on visible {
                        SequentialAnimation {
                            PropertyAction { target: winnerCardVisual; property: "x"; value: -80 }
                            PropertyAction { target: winnerCardVisual; property: "opacity"; value: 0 }
                            NumberAnimation { target: winnerCardVisual; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
                            NumberAnimation { target: winnerCardVisual; property: "opacity"; to: 1; duration: 200 }
                        }
                    }
                }

                // Green glow for winner
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 10
                    color: "transparent"
                    border.color: root.winGreen
                    border.width: 2
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

    // Split indicator
    Rectangle {
        anchors.top: parent.bottom
        anchors.topMargin: -8
        anchors.horizontalCenter: parent.horizontalCenter
        width: splitText.width + 24
        height: 28
        radius: 14
        color: root.copperAccent
        visible: engine.loserCard && engine.winnerCard &&
                 engine.loserCard.rank === engine.winnerCard.rank

        HoverHandler { id: doubletHover }
        ToolTip {
            visible: doubletHover.hovered
            text: "Both cards share the same rank — the banker takes half of all bets on this rank"
            delay: 600
        }
        opacity: 0

        NumberAnimation on opacity {
            from: 0; to: 1; duration: 400
            running: engine.loserCard && engine.winnerCard &&
                     engine.loserCard.rank === engine.winnerCard.rank
        }

        Text {
            id: splitText
            anchors.centerIn: parent
            text: "✦ DOUBLET ✦"
            font.family: root.bodyFont
            font.pixelSize: 12
            font.letterSpacing: 2
            font.bold: true
            color: root.shadowBlack
        }
    }
}
