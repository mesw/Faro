import QtQuick

Item {
    id: goldTextRoot
    width: textElement.width
    height: textElement.height

    property alias text: textElement.text
    property alias font: textElement.font
    property bool shimmerEnabled: true

    Text {
        id: textElement
        color: root.goldAccent
        font.family: root.displayFont
        font.pixelSize: 24
    }

    // Shimmer overlay
    Rectangle {
        anchors.fill: parent
        clip: true
        color: "transparent"
        visible: shimmerEnabled

        Rectangle {
            id: shimmerBar
            width: parent.width * 0.25
            height: parent.height * 2
            rotation: -15
            color: root.goldBright
            opacity: 0.12
            x: -width

            SequentialAnimation on x {
                loops: Animation.Infinite
                PauseAnimation { duration: 5000 }
                NumberAnimation {
                    to: goldTextRoot.width + shimmerBar.width
                    duration: 800
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation { to: -shimmerBar.width; duration: 0 }
            }
        }
    }
}
