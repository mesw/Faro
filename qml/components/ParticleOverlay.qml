import QtQuick

Item {
    id: particleRoot
    anchors.fill: parent

    property int particleCount: 20
    property color particleColor: root.goldAccent
    property real maxOpacity: 0.2

    Repeater {
        model: particleCount

        Rectangle {
            id: particle
            readonly property real baseX: Math.random() * particleRoot.width
            readonly property real baseY: Math.random() * particleRoot.height
            readonly property real size: 1 + Math.random() * 3
            readonly property int animDuration: 4000 + Math.random() * 8000

            x: baseX
            y: baseY
            width: size
            height: size
            radius: size / 2
            color: particleRoot.particleColor
            opacity: 0

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: particle.animDuration * Math.random() }
                NumberAnimation {
                    to: particleRoot.maxOpacity * (0.5 + Math.random() * 0.5)
                    duration: 1500 + Math.random() * 1500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 0
                    duration: 2000 + Math.random() * 2000
                    easing.type: Easing.InOutSine
                }
            }

            NumberAnimation on y {
                loops: Animation.Infinite
                from: particle.baseY
                to: particle.baseY - 20 - Math.random() * 40
                duration: particle.animDuration
                easing.type: Easing.InOutSine
            }
        }
    }
}
