import QtQuick
import QtQuick.Layouts
import Faro.Engine 1.0

Item {
    id: trayRoot

    required property GameEngine engine

    height: 110

    // Returns the center point of a player's purse, in trayRoot's coordinate space
    function purseCenter(seatIndex) {
        for (var i = 0; i < purseRepeater.count; ++i) {
            var item = purseRepeater.itemAt(i)
            if (item && item.playerSeatIndex === seatIndex) {
                return item.mapToItem(trayRoot, item.width / 2, item.height / 2)
            }
        }
        return Qt.point(trayRoot.width / 2, trayRoot.height / 2)
    }

    Rectangle {
        anchors.fill: parent
        color: "#18080408"
        border.color: root.goldDim
        border.width: 0.5
    }

    // Build ordered seat list: leftSeats (reversed) | seat0 | rightSeats
    // Left: odd seatIndex (1, 3) — sorted descending so 3 is outermost
    // Right: even seatIndex > 0 (2, 4) — sorted ascending so 4 is outermost
    property var leftSeats: {
        var arr = []
        for (var i = 0; i < engine.players.length; ++i) {
            var p = engine.players[i]
            if (p.seatIndex > 0 && p.seatIndex % 2 === 1) arr.push(p)
        }
        arr.sort(function(a, b) { return b.seatIndex - a.seatIndex })
        return arr
    }

    property var rightSeats: {
        var arr = []
        for (var i = 0; i < engine.players.length; ++i) {
            var p = engine.players[i]
            if (p.seatIndex > 0 && p.seatIndex % 2 === 0) arr.push(p)
        }
        arr.sort(function(a, b) { return a.seatIndex - b.seatIndex })
        return arr
    }

    // Combine all purses in display order so purseRepeater can index them
    property var allPurseModels: {
        var arr = []
        for (var i = 0; i < leftSeats.length; ++i)  arr.push(leftSeats[i])
        if (engine.players.length > 0) arr.push(engine.players[0])
        for (var j = 0; j < rightSeats.length; ++j) arr.push(rightSeats[j])
        return arr
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            id: purseRepeater
            model: trayRoot.allPurseModels

            delegate: Item {
                id: purseDelegate
                property var  playerModel:     modelData
                property int  playerSeatIndex: modelData ? modelData.seatIndex : -1
                property bool isHuman:         modelData ? modelData.seatIndex === 0 : false
                property bool isActive:        modelData ? modelData.chips > 0 : false

                width:  isHuman ? 140 : 110
                height: 90

                opacity: isActive ? 1.0 : 0.4
                Behavior on opacity { NumberAnimation { duration: 400 } }

                Rectangle {
                    anchors.fill: parent; radius: 8
                    color: isHuman ? "#20c9a227" : "#10ffffff"
                    border.color: playerModel ? playerModel.colorHex : root.goldDim
                    border.width: isHuman ? 1.5 : 0.5
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    // Color pip + name
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: playerModel ? playerModel.colorHex : "gray"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: playerModel ? playerModel.name : ""
                            font.family: root.bodyFont; font.pixelSize: 10; font.letterSpacing: 1
                            color: isHuman ? root.goldAccent : root.ivoryWhite
                        }
                    }

                    // Chip count
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        Text {
                            text: "♦"
                            font.pixelSize: isHuman ? 16 : 12
                            color: playerModel ? playerModel.colorHex : "gray"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: purseChipsLabel
                            text: playerModel ? playerModel.chips : 0
                            font.family: root.monoFont
                            font.pixelSize: isHuman ? 20 : 15
                            font.bold: true
                            color: isHuman ? root.goldBright : root.ivoryWhite
                        }
                    }

                    // "Réfléchit…" — AI only when thinking
                    Text {
                        visible: !isHuman && playerModel && playerModel.isThinking
                        text: "Réfléchit…"
                        font.family: root.bodyFont; font.pixelSize: 9; font.italic: true
                        color: root.goldDim; opacity: 0.7
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
