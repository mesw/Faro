import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: titleRoot
    signal startGame()

    // Lantern glow effect behind title
    Rectangle {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -60
        width: 500
        height: 500
        radius: 250
        color: "transparent"
        opacity: 0.3

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = width / 2
                var cy = height / 2
                var grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, width / 2)
                grad.addColorStop(0.0, "#50c9a227")
                grad.addColorStop(0.4, "#28c9a227")
                grad.addColorStop(1.0, "transparent")
                ctx.fillStyle = grad
                ctx.fillRect(0, 0, width, height)
            }
        }

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.25; duration: 3000; easing.type: Easing.InOutSine }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 8

        // Ornamental line above
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: ornLine.width + 40
            height: 1
            color: root.goldAccent
            opacity: titleFadeIn.running ? 0 : 0.5

            Behavior on opacity { NumberAnimation { duration: 1000 } }
        }

        // Subtitle above
        Text {
            id: subtitleAbove
            anchors.horizontalCenter: parent.horizontalCenter
            text: "— JEU DE CARTES DE —"
            font.family: root.bodyFont
            font.pixelSize: 14
            font.letterSpacing: 8
            color: root.goldDim
            opacity: 0

            NumberAnimation on opacity {
                id: subAboveFade
                from: 0; to: 1
                duration: 1200
                easing.type: Easing.OutCubic
                running: false
            }
        }

        // Main title
        Text {
            id: titleText
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PHARAON"
            font.family: root.displayFont
            font.pixelSize: 120
            font.weight: Font.Bold
            font.letterSpacing: 24
            color: root.goldAccent
            opacity: 0
            scale: 1.1

            NumberAnimation on opacity {
                id: titleFadeIn
                from: 0; to: 1
                duration: 2000
                easing.type: Easing.OutCubic
                running: true
                onFinished: {
                    subAboveFade.running = true
                    subBelowFade.running = true
                    ornFade.running = true
                    dealBtnFade.running = true
                }
            }
            NumberAnimation on scale {
                from: 1.1; to: 1.0
                duration: 2500
                easing.type: Easing.OutCubic
                running: true
            }

            // Gold shimmer effect
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                clip: true

                Rectangle {
                    id: shimmer
                    width: parent.width * 0.3
                    height: parent.height * 2
                    rotation: -20
                    color: root.goldBright
                    opacity: 0.15
                    x: -width

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        PauseAnimation { duration: 4000 }
                        NumberAnimation {
                            to: titleText.width + shimmer.width
                            duration: 1200
                            easing.type: Easing.InOutCubic
                        }
                        PauseAnimation { duration: 2000 }
                        NumberAnimation {
                            to: -shimmer.width
                            duration: 0
                        }
                    }
                }
            }
        }

        // Subtitle below
        Text {
            id: subtitleBelow
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Un jeu de la Cour du Roi Soleil"
            font.family: root.bodyFont
            font.pixelSize: 18
            font.italic: true
            color: root.ivoryWhite
            opacity: 0

            NumberAnimation on opacity {
                id: subBelowFade
                from: 0; to: 0.7
                duration: 1200
                easing.type: Easing.OutCubic
                running: false
            }
        }

        // Ornamental line below
        Row {
            id: ornLine
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            opacity: 0

            NumberAnimation on opacity {
                id: ornFade
                from: 0; to: 0.65
                duration: 1000
                running: false
            }

            Rectangle { width: 40; height: 1; color: root.goldAccent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "◆"; font.pixelSize: 8; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 20; height: 1; color: root.goldAccent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "⚜"; font.pixelSize: 20; color: root.goldAccent; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 20; height: 1; color: root.goldAccent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "◆"; font.pixelSize: 8; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 40; height: 1; color: root.goldAccent; anchors.verticalCenter: parent.verticalCenter }
        }

        Item { width: 1; height: 40 }

        // Deal button
        Rectangle {
            id: dealBtn
            anchors.horizontalCenter: parent.horizontalCenter
            width: 240
            height: 56
            radius: 4
            color: "transparent"
            border.color: root.goldAccent
            border.width: 1.5
            opacity: 0

            NumberAnimation on opacity {
                id: dealBtnFade
                from: 0; to: 1
                duration: 800
                running: false
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: root.goldAccent
                opacity: dealBtnMouse.containsMouse ? 0.15 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Text {
                anchors.centerIn: parent
                text: "PRENDRE PLACE"
                font.family: root.bodyFont
                font.pixelSize: 16
                font.letterSpacing: 4
                color: root.goldAccent
            }

            MouseArea {
                id: dealBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: titleRoot.startGame()
                ToolTip.visible: containsMouse
                ToolTip.text: "Begin a new game of Pharaon"
                ToolTip.delay: 600
            }

            // Subtle pulse
            SequentialAnimation on border.color {
                loops: Animation.Infinite
                ColorAnimation { to: root.goldBright; duration: 2000; easing.type: Easing.InOutSine }
                ColorAnimation { to: root.goldAccent; duration: 2000; easing.type: Easing.InOutSine }
            }
        }

        Item { width: 1; height: 30 }

        // Credits
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Built with Qt 6.8 · Open Source"
            font.family: root.bodyFont
            font.pixelSize: 12
            color: root.goldDim
            opacity: 0.5
        }
    }

    // Decorative card fan at bottom
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -30
        opacity: 0.15

        Repeater {
            model: ["A♠", "K♠", "Q♠", "J♠", "10♠"]
            Text {
                text: modelData
                font.family: root.displayFont
                font.pixelSize: 48
                color: root.ivoryWhite
                rotation: (index - 2) * 8
                transformOrigin: Item.Bottom
            }
        }
    }
}
