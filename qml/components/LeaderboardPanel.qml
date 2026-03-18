import QtQuick
import QtQuick.Controls
import Faro.Engine 1.0

Item {
    id: lbRoot
    required property GameEngine engine

    Rectangle {
        anchors.fill: parent
        color: "#f01c0e18"
        radius: 12
        border.color: root.goldAccent; border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "TABLEAU D'HONNEUR"
            font.family: root.displayFont; font.pixelSize: 22; font.letterSpacing: 4
            color: root.goldAccent
        }

        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.4 }

        // Header row
        Row {
            width: parent.width
            Text { width: 32;  text: "#";        font.family: root.monoFont; font.pixelSize: 11; color: root.goldDim }
            Text { width: 60;  text: "NOM";      font.family: root.monoFont; font.pixelSize: 11; color: root.goldDim }
            Text { width: 80;  text: "JETONS";   font.family: root.monoFont; font.pixelSize: 11; color: root.goldDim }
            Text { width: 60;  text: "DONNES";   font.family: root.monoFont; font.pixelSize: 11; color: root.goldDim }
        }

        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }

        // Entries
        ListView {
            width: parent.width
            height: lbRoot.height - 120
            model: engine.leaderboard
            clip: true

            delegate: Item {
                width: parent ? parent.width : 0
                height: 28
                required property var modelData
                required property int index

                Row {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: 32
                        text: index + 1
                        font.family: root.monoFont; font.pixelSize: 13; font.bold: true
                        color: index === 0 ? root.goldBright : root.goldDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 60
                        text: modelData.initials || "---"
                        font.family: root.monoFont; font.pixelSize: 14; font.bold: true
                        color: index === 0 ? root.goldBright : root.ivoryWhite
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 80
                        text: modelData.chips || 0
                        font.family: root.monoFont; font.pixelSize: 13
                        color: root.goldAccent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 60
                        text: modelData.turn || 0
                        font.family: root.monoFont; font.pixelSize: 12
                        color: root.ivoryWhite; opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: root.goldDim; opacity: 0.1
                }
            }

            Text {
                visible: engine.leaderboard.length === 0
                anchors.centerIn: parent
                text: "Aucune entrée"
                font.family: root.bodyFont; font.pixelSize: 14; font.italic: true
                color: root.goldDim; opacity: 0.6
            }
        }
    }
}
