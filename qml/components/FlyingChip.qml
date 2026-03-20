import QtQuick

Item {
    id: flyingChip

    property real fromX:  0
    property real fromY:  0
    property real toX:    0
    property real toY:    0
    property int  amount: 1
    property bool contre: false
    property bool isWin:  false

    width: 36; height: 36
    x: fromX; y: fromY

    onVisibleChanged: {
        if (visible) {
            x = fromX; y = fromY; opacity = 1
            flyAnim.restart()
        }
    }

    BettingChip {
        anchors.fill: parent
        value: flyingChip.amount
        contre: flyingChip.contre
    }

    ParallelAnimation {
        id: flyAnim
        running: false

        NumberAnimation {
            target: flyingChip; property: "x"
            to: flyingChip.toX
            duration: flyingChip.isWin ? 600 : 800
            easing.type: flyingChip.isWin ? Easing.OutBack : Easing.InQuad
        }
        NumberAnimation {
            target: flyingChip; property: "y"
            to: flyingChip.toY
            duration: flyingChip.isWin ? 600 : 800
            easing.type: flyingChip.isWin ? Easing.OutBack : Easing.InQuad
        }
        NumberAnimation {
            target: flyingChip; property: "opacity"
            from: 1; to: flyingChip.isWin ? 0.9 : 0
            duration: flyingChip.isWin ? 600 : 800
        }

        onFinished: flyingChip.visible = false
    }
}
