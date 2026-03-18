import QtQuick

Item {
    id: flyingCard

    property real fromX: 0
    property real fromY: 0
    property real toX:   0
    property real toY:   0
    property int  cardRank: 1
    property int  cardSuit: 0

    width: 70; height: 100
    x: fromX; y: fromY

    Card {
        anchors.fill: parent
        rank: flyingCard.cardRank
        suit: flyingCard.cardSuit
        faceUp: true
    }

    ParallelAnimation {
        id: flyAnim
        running: true

        NumberAnimation {
            target: flyingCard; property: "x"
            to: flyingCard.toX
            duration: 380; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: flyingCard; property: "y"
            to: flyingCard.toY
            duration: 380; easing.type: Easing.OutCubic
        }

        onFinished: flyingCard.destroy()
    }
}
