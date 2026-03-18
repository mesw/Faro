import QtQuick

Item {
    id: flyingChip

    property real fromX:  0
    property real fromY:  0
    property real toX:    0
    property real toY:    0
    property int  amount: 1
    property bool contre: false

    width: 36; height: 36
    x: fromX; y: fromY

    BettingChip {
        anchors.fill: parent
        value: flyingChip.amount
        contre: flyingChip.contre
    }

    ParallelAnimation {
        id: flyAnim
        running: true

        NumberAnimation {
            target: flyingChip; property: "x"
            to: flyingChip.toX
            duration: 420; easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: flyingChip; property: "y"
            to: flyingChip.toY
            duration: 420; easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: flyingChip; property: "opacity"
            from: 1; to: 0
            duration: 420
        }

        onFinished: flyingChip.destroy()
    }
}
