import QtQuick
import QtQuick.Controls
import Faro.Engine 1.0

Item {
    id: panelRoot
    required property GameEngine engine

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#12080408"
        radius: 8
        border.color: root.goldDim; border.width: 0.5
    }

    Column {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        // Header
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "JOUEURS"
            font.family: root.bodyFont; font.pixelSize: 10; font.letterSpacing: 3
            color: root.goldDim
            topPadding: 6; bottomPadding: 4
        }
        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }

        // Player list
        ListView {
            id: playerList
            width: parent.width
            height: panelRoot.height - 28
            model: engine.players
            clip: true

            delegate: Item {
                width: playerList.width
                height: 52
                required property var modelData
                required property int index

                readonly property bool isHuman: modelData.playerType === 0  // PlayerModel.Human

                // Row highlight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 6
                    color: isHuman ? "#20c9a227" : "#10ffffff"
                    border.color: modelData.colorHex
                    border.width: 0.5
                    opacity: 0.7
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    // Colour pip
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: modelData.colorHex
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Name + status
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 70

                        Text {
                            text: modelData.name
                            font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 1
                            color: isHuman ? root.goldAccent : root.ivoryWhite
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            visible: modelData.playerType !== 0  // AI only
                            text: modelData.isThinking ? "Réfléchit…" : "En attente"
                            font.family: root.bodyFont; font.pixelSize: 10; font.italic: true
                            color: root.goldDim; opacity: 0.7
                        }
                    }

                    Item { width: 1 }

                    // Chip count
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            text: "♦"
                            font.pixelSize: 12; color: modelData.colorHex
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.chips
                            font.family: root.monoFont; font.pixelSize: 13; font.bold: true
                            color: isHuman ? root.goldBright : root.ivoryWhite
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: root.goldDim; opacity: 0.1
                }
            }
        }
    }
}
