import QtQuick
import QtQuick.Layouts
import Faro.Engine 1.0

Item {
    id: tableRoot

    required property GameEngine engine
    property int  betAmount: 5
    property bool contre:    false

    readonly property var topRowRanks:    [13, 12, 11, 10, 9, 8, 7]
    readonly property var bottomRowRanks: [6, 5, 4, 3, 2, 1]
    readonly property var rankNames: ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

    // Expose slot center for animation coordinate mapping
    function slotCenter(rank) {
        // Walk all slot items to find matching rank
        for (var i = 0; i < slotRepeaterTop.count; ++i) {
            var item = slotRepeaterTop.itemAt(i)
            if (item && item.cardRank === rank) {
                return mapFromItem(item, item.width / 2, item.height / 2)
            }
        }
        for (var j = 0; j < slotRepeaterBottom.count; ++j) {
            var item2 = slotRepeaterBottom.itemAt(j)
            if (item2 && item2.cardRank === rank) {
                return mapFromItem(item2, item2.width / 2, item2.height / 2)
            }
        }
        return Qt.point(width / 2, height / 2)
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Repeater {
                id: slotRepeaterTop
                model: tableRoot.topRowRanks
                delegate: tableCardDelegate
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Repeater {
                id: slotRepeaterBottom
                model: tableRoot.bottomRowRanks
                delegate: tableCardDelegate
            }
        }
    }

    Component {
        id: tableCardDelegate

        Item {
            id: cardSlot
            width: 78; height: 120

            readonly property int cardRank: modelData
            readonly property bool hasBet: {
                var bets = engine.currentBets
                return bets.hasOwnProperty(String(cardRank))
            }
            readonly property bool isDead: { engine.cardsRemaining; return engine.cardsShownForRank(cardRank) >= 4 }
            readonly property int  shownCount: engine.cardsShownForRank(cardRank)

            // Layout card (always spades, always face-up)
            Card {
                anchors.fill: parent
                rank: cardSlot.cardRank
                suit: 0
                faceUp: true
                highlighted: cardSlotMouse.containsMouse && !isDead && tableRoot.enabled
                dimmed: isDead
            }

            // ── Human bet chip ──
            Rectangle {
                id: betChip
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 10
                width: 32; height: 32; radius: 16
                visible: hasBet
                z: 5

                property bool isCoppered: {
                    if (!hasBet) return false
                    var bet = engine.currentBets[String(cardRank)]
                    return bet ? bet.contre : false
                }

                gradient: Gradient {
                    GradientStop { position: 0; color: betChip.isCoppered ? "#d4845a" : root.goldBright }
                    GradientStop { position: 1; color: betChip.isCoppered ? "#8a5230" : root.goldDim }
                }
                border.color: "#40000000"; border.width: 0.5

                Rectangle {
                    anchors.centerIn: parent; width: 22; height: 22; radius: 11
                    color: "transparent"; border.color: "#40ffffff"; border.width: 0.5
                }

                Text {
                    anchors.centerIn: parent
                    text: hasBet ? (engine.currentBets[String(cardRank)] ? engine.currentBets[String(cardRank)].amount : "") : ""
                    font.family: root.monoFont; font.pixelSize: 10; font.bold: true
                    color: "#1a0e00"
                }

                Rectangle {
                    anchors.top: parent.top; anchors.right: parent.right
                    anchors.topMargin: -4; anchors.rightMargin: -4
                    width: 12; height: 12; radius: 6
                    color: root.copperAccent; border.color: "#60000000"; border.width: 0.5
                    visible: betChip.isCoppered
                }

                scale: 0
                Component.onCompleted: scaleAnim.running = true
                NumberAnimation on scale { id: scaleAnim; from: 0; to: 1; duration: 200; easing.type: Easing.OutBack; running: false }
            }

            // ── AI bet chips (one small circle per AI player who has a bet here) ──
            Item {
                anchors.fill: parent
                z: 4

                Repeater {
                    model: { engine.allPlayerBets; return engine.aiBetsForRank(cardSlot.cardRank) }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: 18; height: 18; radius: 9
                        color: modelData.colorHex
                        border.color: "#60000000"; border.width: 0.5
                        x: parent.width / 2 - 9 + index * 10
                        y: parent.height / 2 + 14 + index * 5
                        opacity: 0.85

                        Text {
                            anchors.centerIn: parent
                            text: modelData.amount
                            font.family: root.monoFont; font.pixelSize: 7; font.bold: true
                            color: "#1a0e00"
                        }

                        // Copper contre dot
                        Rectangle {
                            visible: modelData.contre
                            anchors.top: parent.top; anchors.right: parent.right
                            anchors.topMargin: -2; anchors.rightMargin: -2
                            width: 6; height: 6; radius: 3
                            color: root.copperAccent
                        }
                    }
                }
            }

            // ── Shown count pips ──
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: -6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 3; z: 3

                Repeater {
                    model: shownCount
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: {
                            var cards = engine.getShownCardsForRank(cardSlot.cardRank)
                            if (index < cards.length) {
                                var t = cards[index].type
                                if (t === "winner") return root.winGreen
                                if (t === "loser")  return root.cardRed
                                if (t === "souche") return root.goldDim
                            }
                            return root.goldDim
                        }
                        border.color: "#40000000"; border.width: 0.5
                    }
                }
            }

            MouseArea {
                id: cardSlotMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: (tableRoot.enabled && !isDead) ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if (!tableRoot.enabled || isDead) return
                    if (hasBet) engine.removeBet(cardRank)
                    else        engine.placeBet(cardRank, tableRoot.betAmount, tableRoot.contre)
                }
            }
        }
    }
}
