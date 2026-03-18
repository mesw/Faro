import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Faro.Engine 1.0

Item {
    id: resultsRoot

    required property GameEngine engine
    signal playAgain()
    signal backToTitle()

    property int finalChips: engine.playerChips
    property bool isWin: finalChips > 100

    // Dramatic background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: isWin ? "#0e2014" : "#200c0c" }
            GradientStop { position: 1.0; color: "#0a0608" }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: isWin ? "LA FORTUNE SOURIT" : "LA BANQUE GAGNE"
            font.family: root.displayFont
            font.pixelSize: 48
            font.letterSpacing: 6
            color: isWin ? root.goldBright : root.cardRed
            opacity: 0

            NumberAnimation on opacity {
                from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic
                running: true
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: isWin ? "Vous quittez la table plus riche." : "Que la chance vous sourie à nouveau."
            font.family: root.bodyFont
            font.pixelSize: 18
            font.italic: true
            color: root.ivoryWhite
            opacity: 0

            NumberAnimation on opacity {
                from: 0; to: 0.7; duration: 1200; running: true
            }
        }

        Item { width: 1; height: 20 }

        // Chip count with animated counter
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Text {
                text: "♦"
                font.pixelSize: 36
                color: root.goldBright
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: chipCounter
                property int displayValue: 0
                text: displayValue
                font.family: root.monoFont
                font.pixelSize: 64
                font.bold: true
                color: isWin ? root.goldBright : root.cardRed

                NumberAnimation on displayValue {
                    from: 100
                    to: resultsRoot.finalChips
                    duration: 2000
                    easing.type: Easing.OutCubic
                    running: true
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var diff = finalChips - 100;
                return diff >= 0 ? "+" + diff + " jetons" : diff + " jetons";
            }
            font.family: root.monoFont
            font.pixelSize: 16
            color: isWin ? root.winGreen : root.cardRed
            opacity: 0.8
        }

        Item { width: 1; height: 30 }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            // Play again
            Rectangle {
                width: 200; height: 48; radius: 6
                gradient: Gradient {
                    GradientStop { position: 0; color: root.goldAccent }
                    GradientStop { position: 1; color: root.goldDim }
                }

                Text {
                    anchors.centerIn: parent
                    text: "REJOUER"
                    font.family: root.bodyFont
                    font.pixelSize: 14
                    font.letterSpacing: 3
                    color: root.shadowBlack
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: resultsRoot.playAgain()
                    ToolTip.visible: containsMouse
                    ToolTip.text: "Start a new game with 100 jetons"
                    ToolTip.delay: 600
                }
            }

            // Back to title
            Rectangle {
                width: 200; height: 48; radius: 6
                color: "transparent"
                border.color: root.goldDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "QUITTER LA TABLE"
                    font.family: root.bodyFont
                    font.pixelSize: 14
                    font.letterSpacing: 3
                    color: root.goldAccent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: resultsRoot.backToTitle()
                    ToolTip.visible: containsMouse
                    ToolTip.text: "Return to the title screen"
                    ToolTip.delay: 600
                }
            }
        }
    }

    // Celebratory particles for wins
    Repeater {
        model: isWin ? 50 : 0
        Rectangle {
            id: confetti
            readonly property real sx: Math.random() * resultsRoot.width
            readonly property real sy: -20 - Math.random() * 200
            readonly property color confettiColor: ["#d4a843", "#f0d060", "#b87333", "#f5f0e1"][Math.floor(Math.random() * 4)]

            x: sx
            y: sy
            width: 3 + Math.random() * 5
            height: width * (1 + Math.random() * 2)
            color: confettiColor
            rotation: Math.random() * 360
            opacity: 0

            SequentialAnimation {
                running: true
                PauseAnimation { duration: Math.random() * 1500 }
                ParallelAnimation {
                    NumberAnimation { target: confetti; property: "y"; to: resultsRoot.height + 50; duration: 2500 + Math.random() * 2000; easing.type: Easing.InQuad }
                    NumberAnimation { target: confetti; property: "opacity"; from: 0; to: 0.8; duration: 300 }
                    NumberAnimation { target: confetti; property: "rotation"; to: confetti.rotation + 360 * (Math.random() > 0.5 ? 1 : -1); duration: 3000 }
                    NumberAnimation { target: confetti; property: "x"; to: confetti.sx + (Math.random() - 0.5) * 200; duration: 3000; easing.type: Easing.InOutSine }
                }
                NumberAnimation { target: confetti; property: "opacity"; to: 0; duration: 500 }
            }
        }
    }
}
