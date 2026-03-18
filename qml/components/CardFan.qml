import QtQuick

Item {
    id: fanRoot
    width: 300
    height: 120

    property var cards: ["A", "K", "Q", "J", "10"]
    property real fanAngle: 8
    property real cardSpacing: -25

    Row {
        anchors.centerIn: parent
        spacing: cardSpacing

        Repeater {
            model: fanRoot.cards

            Item {
                width: 60
                height: 90
                rotation: (index - Math.floor(fanRoot.cards.length / 2)) * fanRoot.fanAngle
                transformOrigin: Item.Bottom

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: root.cardWhite
                    border.color: "#20000000"
                    border.width: 0.5

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "\u2660"
                        font.family: root.displayFont
                        font.pixelSize: 18
                        color: "#2a2a2a"
                    }
                }
            }
        }
    }
}
