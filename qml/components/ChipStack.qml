import QtQuick

Item {
    id: chipStackRoot
    width: 40
    height: 60

    property int amount: 0
    property color chipColor: root.goldAccent

    readonly property int chipCount: {
        if (amount <= 0) return 0;
        if (amount <= 5) return 1;
        if (amount <= 15) return 2;
        if (amount <= 30) return 3;
        return 4;
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -6

        Repeater {
            model: chipCount

            Rectangle {
                width: 36
                height: 12
                radius: 6

                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(chipStackRoot.chipColor, 1.2) }
                    GradientStop { position: 0.5; color: chipStackRoot.chipColor }
                    GradientStop { position: 1; color: Qt.darker(chipStackRoot.chipColor, 1.3) }
                }

                border.color: "#30000000"
                border.width: 0.5

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: 1
                    color: "#30ffffff"
                }
            }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -14
        anchors.horizontalCenter: parent.horizontalCenter
        text: amount > 0 ? amount : ""
        font.family: root.monoFont
        font.pixelSize: 9
        font.bold: true
        color: root.ivoryWhite
        visible: amount > 0
    }
}
