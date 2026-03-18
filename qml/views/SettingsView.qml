import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Faro.Engine 1.0


Item {
    id: settingsRoot
    signal backToTitle()

    // Dramatic background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1c0e14" }
            GradientStop { position: 1.0; color: "#0a0608" }
        }
    }

    // ── Content ──
    Column {
        anchors.centerIn: parent
        spacing: 0
        width: Math.min(parent.width - 80, 520)

        // Title
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PARAMÈTRES"
            font.family: root.displayFont
            font.pixelSize: 42
            font.letterSpacing: 8
            color: root.goldAccent
        }

        Item { width: 1; height: 8 }
        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.4 }
        Item { width: 1; height: 32 }

        // ── Betting timer ──
        SettingsRow {
            width: parent.width
            label: "MINUTERIE DE MISE"
            sublabel: Math.round(AppSettings.bettingTimerMs / 1000) + " secondes"
        }
        Item { width: 1; height: 10 }
        Slider {
            width: parent.width
            from: 1000; to: 30000; stepSize: 1000
            value: AppSettings.bettingTimerMs
            onValueChanged: AppSettings.bettingTimerMs = value

            background: Rectangle {
                x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: parent.availableWidth; height: 4; radius: 2
                color: root.goldDim; opacity: 0.4
                Rectangle {
                    width: parent.parent.visualPosition * parent.width
                    height: parent.height; radius: parent.radius
                    color: root.goldAccent
                }
            }
            handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: 20; height: 20; radius: 10
                color: root.goldBright
                border.color: root.goldDim; border.width: 1
            }
        }
        // Marks
        Row {
            width: parent.width
            Repeater {
                model: [2, 5, 10, 20, 30]
                Item {
                    width: parent.parent.width / 4 * (index < 4 ? 1 : 0)
                    height: 16
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData + "s"
                        font.family: root.monoFont; font.pixelSize: 10
                        color: root.goldDim; opacity: 0.6
                    }
                }
            }
        }

        Item { width: 1; height: 28 }
        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }
        Item { width: 1; height: 28 }

        // ── AI opponents ──
        SettingsRow {
            width: parent.width
            label: "ADVERSAIRES IA"
            sublabel: AppSettings.aiPlayerCount === 0 ? "Aucun" : AppSettings.aiPlayerCount + " joueur" + (AppSettings.aiPlayerCount > 1 ? "s" : "")
        }
        Item { width: 1; height: 12 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Repeater {
                model: [0, 1, 2, 3, 4]
                Rectangle {
                    width: 52; height: 40; radius: 6
                    color: AppSettings.aiPlayerCount === modelData ? root.goldAccent : "#30ffffff"
                    border.color: root.goldDim; border.width: 0.5
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: root.monoFont; font.pixelSize: 16; font.bold: true
                        color: AppSettings.aiPlayerCount === modelData ? root.shadowBlack : root.ivoryWhite
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppSettings.aiPlayerCount = modelData
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        Item { width: 1; height: 28 }
        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }
        Item { width: 1; height: 28 }

        // ── Starting chips ──
        SettingsRow {
            width: parent.width
            label: "JETONS DE DÉPART"
            sublabel: AppSettings.startingChips + " jetons"
        }
        Item { width: 1; height: 12 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Repeater {
                model: [50, 100, 200, 500]
                Rectangle {
                    width: 72; height: 40; radius: 6
                    color: AppSettings.startingChips === modelData ? root.goldAccent : "#30ffffff"
                    border.color: root.goldDim; border.width: 0.5
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: root.monoFont; font.pixelSize: 14; font.bold: true
                        color: AppSettings.startingChips === modelData ? root.shadowBlack : root.ivoryWhite
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppSettings.startingChips = modelData
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        Item { width: 1; height: 28 }
        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }
        Item { width: 1; height: 28 }

        // ── Multiplayer URL ──
        SettingsRow {
            width: parent.width
            label: "SERVEUR MULTIJOUEUR"
            sublabel: AppSettings.serverUrl === "" ? "Hors ligne" : AppSettings.serverUrl
        }
        Item { width: 1; height: 10 }
        TextField {
            width: parent.width
            placeholderText: "ws://localhost:8787"
            text: AppSettings.serverUrl
            font.family: root.monoFont; font.pixelSize: 13
            color: root.ivoryWhite
            placeholderTextColor: root.goldDim
            background: Rectangle {
                color: "#20ffffff"
                radius: 6
                border.color: root.goldDim; border.width: 0.5
            }
            onTextChanged: AppSettings.serverUrl = text
        }

        Item { width: 1; height: 40 }

        // ── Buttons ──
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            // Save
            Rectangle {
                width: 200; height: 48; radius: 6
                gradient: Gradient {
                    GradientStop { position: 0; color: root.goldAccent }
                    GradientStop { position: 1; color: root.goldDim }
                }
                Text {
                    anchors.centerIn: parent
                    text: "SAUVEGARDER"
                    font.family: root.bodyFont; font.pixelSize: 14; font.letterSpacing: 3
                    color: root.shadowBlack
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { AppSettings.save(); settingsRoot.backToTitle() }
                }
            }

            // Back without saving
            Rectangle {
                width: 160; height: 48; radius: 6
                color: "transparent"
                border.color: root.goldDim; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "RETOUR"
                    font.family: root.bodyFont; font.pixelSize: 14; font.letterSpacing: 3
                    color: root.goldAccent
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { AppSettings.load(); settingsRoot.backToTitle() }
                }
            }
        }
    }

    // ── Helper component ──
    component SettingsRow: Item {
        property string label: ""
        property string sublabel: ""
        height: labelText.height
        Text {
            id: labelText
            text: label
            font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3
            color: root.goldDim
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: labelText.verticalCenter
            text: sublabel
            font.family: root.monoFont; font.pixelSize: 12
            color: root.goldAccent
        }
    }
}
