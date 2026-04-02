import QtQuick

Item {
    id: flyingCard

    property real fromX: 0
    property real fromY: 0
    property real toX:   0
    property real toY:   0
    property int  cardRank: 1
    property int  cardSuit: 0
    property real endRotation: (Math.random() > 0.5 ? 1 : -1) * (5 + Math.random() * 12)

    width: 70; height: 100
    x: fromX; y: fromY
    transformOrigin: Item.Center

    onVisibleChanged: {
        if (visible) {
            x = fromX; y = fromY; rotation = 0
            endRotation = (Math.random() > 0.5 ? 1 : -1) * (5 + Math.random() * 12)
            flyAnim.restart()
        }
    }

    Card {
        anchors.fill: parent
        rank: flyingCard.cardRank
        suit: flyingCard.cardSuit
        faceUp: true
    }

    ParallelAnimation {
        id: flyAnim
        running: false

        NumberAnimation {
            target: flyingCard; property: "x"
            to: flyingCard.toX
            duration: 2000; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: flyingCard; property: "y"
            to: flyingCard.toY
            duration: 2000; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: flyingCard; property: "rotation"
            to: flyingCard.endRotation
            duration: 2000; easing.type: Easing.OutSine
        }

        onFinished: flyingCard.visible = false
    }
}
