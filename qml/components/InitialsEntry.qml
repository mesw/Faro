import QtQuick
import QtQuick.Controls

Item {
    id: initialsRoot
    width: 280; height: 140

    signal submitted(string initials)

    property string initials: charA.currentChar + charB.currentChar + charC.currentChar

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#f01c0e18"
        border.color: root.goldAccent; border.width: 1
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "INSCRIVEZ VOS INITIALES"
            font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3
            color: root.goldDim
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            CharSelector { id: charA }
            CharSelector { id: charB }
            CharSelector { id: charC }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 140; height: 36; radius: 6
            gradient: Gradient {
                GradientStop { position: 0; color: root.goldAccent }
                GradientStop { position: 1; color: root.goldDim }
            }
            Text {
                anchors.centerIn: parent
                text: "INSCRIRE"
                font.family: root.bodyFont; font.pixelSize: 13; font.letterSpacing: 3
                color: root.shadowBlack
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: initialsRoot.submitted(initialsRoot.initials)
            }
        }
    }

    // ── Single character selector ──
    component CharSelector: Item {
        width: 44; height: 52
        property string currentChar: chars[currentIndex]
        property int currentIndex: 0
        readonly property var chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")

        Rectangle {
            anchors.fill: parent
            radius: 6; color: "#20ffffff"
            border.color: root.goldAccent; border.width: 1
        }

        // Up arrow
        Text {
            anchors.top: parent.top; anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: "▲"; font.pixelSize: 10; color: root.goldDim
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    currentIndex = (currentIndex + 1) % chars.length
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: currentChar
            font.family: root.monoFont; font.pixelSize: 22; font.bold: true
            color: root.goldBright
        }

        // Down arrow
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: "▼"; font.pixelSize: 10; color: root.goldDim
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    currentIndex = (currentIndex - 1 + chars.length) % chars.length
                }
            }
        }
    }
}
