import QtQuick
import QtQuick.Layouts
import Faro.Engine 1.0

Rectangle {
    id: ckRoot

    required property GameEngine engine

    radius: 12
    color: "#18000000"
    border.color: root.goldDim
    border.width: 0.5

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        // Header
        Text {
            text: "TABLEAU"
            font.family: root.bodyFont
            font.pixelSize: 10
            font.letterSpacing: 3
            color: root.goldDim
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.goldDim
            opacity: 0.2
        }

        // Legend
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Row {
                spacing: 3
                Rectangle { width: 8; height: 8; radius: 4; color: root.winGreen; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "G"; font.family: root.monoFont; font.pixelSize: 8; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                spacing: 3
                Rectangle { width: 8; height: 8; radius: 4; color: root.cardRed; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "P"; font.family: root.monoFont; font.pixelSize: 8; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                spacing: 3
                Rectangle { width: 8; height: 8; radius: 4; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "S"; font.family: root.monoFont; font.pixelSize: 8; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Item { width: 1; height: 4 }

        // One row per rank
        Repeater {
            model: [
                { rank: 13, name: "K" },
                { rank: 12, name: "Q" },
                { rank: 11, name: "J" },
                { rank: 10, name: "10" },
                { rank: 9,  name: "9" },
                { rank: 8,  name: "8" },
                { rank: 7,  name: "7" },
                { rank: 6,  name: "6" },
                { rank: 5,  name: "5" },
                { rank: 4,  name: "4" },
                { rank: 3,  name: "3" },
                { rank: 2,  name: "2" },
                { rank: 1,  name: "A" }
            ]

            delegate: Item {
                width: parent ? parent.width : 0
                height: 26

                readonly property int cardRank: modelData.rank
                readonly property int shownCount: {
                    engine.cardsRemaining  // re-evaluate whenever deck changes
                    return engine.cardsShownForRank(cardRank)
                }
                readonly property bool allShown: shownCount >= 4

                // Background highlight for dead ranks
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: allShown ? "#15ff0000" : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 4

                    // Rank label
                    Text {
                        text: modelData.name
                        font.family: root.monoFont
                        font.pixelSize: 13
                        font.bold: true
                        color: allShown ? root.cardRed : root.ivoryWhite
                        opacity: allShown ? 0.5 : 0.9
                        Layout.preferredWidth: 24
                        horizontalAlignment: Text.AlignRight
                    }

                    // Abacus wire
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.goldDim
                        opacity: 0.3
                    }

                    // 4 bead positions
                    Row {
                        spacing: 3
                        Layout.alignment: Qt.AlignRight

                        Repeater {
                            model: 4

                            Rectangle {
                                id: bead
                                width: 16
                                height: 16
                                radius: 8

                                readonly property bool isShown: index < shownCount
                                readonly property var cardInfo: {
                                    engine.cardsRemaining  // re-evaluate whenever deck changes
                                    if (!isShown) return null;
                                    var cards = engine.getShownCardsForRank(cardRank);
                                    return index < cards.length ? cards[index] : null;
                                }
                                readonly property string cardType: cardInfo ? cardInfo.type : ""

                                color: {
                                    if (!isShown) return "#20ffffff";
                                    switch (cardType) {
                                        case "winner": return root.winGreen;
                                        case "loser": return root.cardRed;
                                        case "souche": return root.goldDim;
                                        case "ecart": return root.copperAccent;
                                        default: return root.goldDim;
                                    }
                                }

                                border.color: isShown ? "#40000000" : "#15ffffff"
                                border.width: 0.5

                                // Suit symbol inside bead
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!bead.cardInfo) return "";
                                        var symbols = ["\u2660", "\u2665", "\u2666", "\u2663"];
                                        return symbols[bead.cardInfo.suit] || "";
                                    }
                                    font.pixelSize: 8
                                    color: "#80000000"
                                    visible: bead.isShown
                                }

                                // Pop-in animation when revealed
                                scale: isShown ? 1.0 : 0.6
                                opacity: isShown ? 1.0 : 0.3

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.0
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: 300 }
                                }
                            }
                        }
                    }

                    // Count
                    Text {
                        text: shownCount + "/4"
                        font.family: root.monoFont
                        font.pixelSize: 9
                        color: allShown ? root.cardRed : root.goldDim
                        opacity: 0.6
                        Layout.preferredWidth: 22
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
