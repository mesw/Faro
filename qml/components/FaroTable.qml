import QtQuick
import QtQuick.Layouts
import Faro.Engine 1.0

Item {
    id: tableRoot

    required property GameEngine engine
    property int betAmount: 5
    property bool contre: false

    // Layout: two rows of cards. Top row: K Q J 10 9 8 7, Bottom row: 6 5 4 3 2 A
    // Plus HIGH CARD slot

    readonly property var topRowRanks: [13, 12, 11, 10, 9, 8, 7]
    readonly property var bottomRowRanks: [6, 5, 4, 3, 2, 1]
    readonly property var rankNames: ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

    Column {
        anchors.centerIn: parent
        spacing: 12

        // Top row
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: tableRoot.topRowRanks
                delegate: tableCardDelegate
            }
        }

        // Bottom row
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: tableRoot.bottomRowRanks
                delegate: tableCardDelegate
            }
        }
    }

    Component {
        id: tableCardDelegate

        Item {
            id: cardSlot
            width: 78
            height: 120

            readonly property int cardRank: modelData
            readonly property bool hasBet: {
                var bets = engine.currentBets;
                return bets.hasOwnProperty(String(cardRank));
            }
            readonly property bool isDead: engine.cardsShownForRank(cardRank) >= 4
            readonly property int shownCount: engine.cardsShownForRank(cardRank)

            // The layout card (always spades, always face-up)
            Card {
                anchors.fill: parent
                rank: cardSlot.cardRank
                suit: 0  // Spades for layout
                faceUp: true
                highlighted: cardSlotMouse.containsMouse && !isDead && tableRoot.enabled
                dimmed: isDead
            }

            // Bet chip overlay
            Rectangle {
                id: betChip
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 10
                width: 32
                height: 32
                radius: 16
                visible: hasBet
                z: 5

                property bool isCoppered: {
                    if (!hasBet) return false;
                    var bet = engine.currentBets[String(cardRank)];
                    return bet ? bet.contre : false;
                }

                gradient: Gradient {
                    GradientStop { position: 0; color: betChip.isCoppered ? "#d4845a" : root.goldBright }
                    GradientStop { position: 1; color: betChip.isCoppered ? "#8a5230" : root.goldDim }
                }

                border.color: "#40000000"
                border.width: 0.5

                // Inner ring
                Rectangle {
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: 11
                    color: "transparent"
                    border.color: "#40ffffff"
                    border.width: 0.5
                }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!hasBet) return "";
                        var bet = engine.currentBets[String(cardRank)];
                        return bet ? bet.amount : "";
                    }
                    font.family: root.monoFont
                    font.pixelSize: 10
                    font.bold: true
                    color: "#1a0e00"
                }

                // Copper penny on top
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -4
                    anchors.rightMargin: -4
                    width: 12; height: 12; radius: 6
                    color: root.copperAccent
                    border.color: "#60000000"
                    border.width: 0.5
                    visible: betChip.isCoppered
                }

                // Entry animation
                scale: 0
                Component.onCompleted: scaleAnim.running = true
                NumberAnimation on scale {
                    id: scaleAnim
                    from: 0; to: 1
                    duration: 200
                    easing.type: Easing.OutBack
                    running: false
                }
            }

            // Shown count indicators (small pips)
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 3
                z: 3

                Repeater {
                    model: shownCount
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: {
                            var cards = engine.getShownCardsForRank(cardSlot.cardRank);
                            if (index < cards.length) {
                                var type = cards[index].type;
                                if (type === "winner") return root.winGreen;
                                if (type === "loser") return root.cardRed;
                                if (type === "souche") return root.goldDim;
                            }
                            return root.goldDim;
                        }
                        border.color: "#40000000"
                        border.width: 0.5
                    }
                }
            }

            MouseArea {
                id: cardSlotMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: (tableRoot.enabled && !isDead) ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if (!tableRoot.enabled || isDead) return;

                    if (hasBet) {
                        engine.removeBet(cardRank);
                    } else {
                        engine.placeBet(cardRank, tableRoot.betAmount, tableRoot.contre);
                    }
                }
            }
        }
    }
}
