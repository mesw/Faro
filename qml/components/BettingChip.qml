import QtQuick

Rectangle {
    id: chipRoot
    width: 36
    height: 36
    radius: 18

    property int value: 5
    property bool contre: false
    property bool interactive: true

    gradient: Gradient {
        GradientStop { position: 0; color: contre ? "#d4845a" : root.goldBright }
        GradientStop { position: 0.6; color: contre ? "#a06030" : root.goldAccent }
        GradientStop { position: 1; color: contre ? "#6a3818" : root.goldDim }
    }

    border.color: "#40000000"
    border.width: 0.5

    // Inner ring
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 10
        height: parent.height - 10
        radius: width / 2
        color: "transparent"
        border.color: "#40ffffff"
        border.width: 0.5
    }

    // Value text
    Text {
        anchors.centerIn: parent
        text: chipRoot.value
        font.family: root.monoFont
        font.pixelSize: 11
        font.bold: true
        color: "#1a0e00"
    }

    // Copper penny indicator
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -2
        width: 12; height: 12; radius: 6
        color: root.copperAccent
        border.color: "#50000000"
        border.width: 0.5
        visible: contre

        Text {
            anchors.centerIn: parent
            text: "¢"
            font.pixelSize: 7
            font.bold: true
            color: "#40000000"
        }
    }

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: interactive
        cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: if (interactive) chipRoot.scale = 0.9
        onReleased: if (interactive) chipRoot.scale = 1.0
    }
}
