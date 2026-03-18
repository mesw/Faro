import QtQuick

Item {
    id: cardRoot
    width: 70
    height: 100

    property int rank: 1       // 1=A .. 13=K
    property int suit: 0       // 0=spades, 1=hearts, 2=diamonds, 3=clubs
    property bool faceUp: true
    property bool highlighted: false
    property bool dimmed: false

    readonly property bool isRed: suit === 1 || suit === 2
    readonly property string rankStr: {
        var names = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
        return names[rank] || "?";
    }
    readonly property string suitStr: {
        var symbols = ["♠", "♥", "♦", "♣"];
        return symbols[suit] || "?";
    }

    // Flip animation
    property bool showFace: faceUp
    Behavior on showFace {
        SequentialAnimation {
            NumberAnimation { target: flipTransform; property: "angle"; to: 90; duration: 200; easing.type: Easing.InQuad }
            ScriptAction { script: {cardFace.visible = cardRoot.showFace; cardBack.visible = !cardRoot.showFace }}
            NumberAnimation { target: flipTransform; property: "angle"; to: 0; duration: 200; easing.type: Easing.OutQuad }
        }
    }

    transform: Rotation {
        id: flipTransform
        origin.x: cardRoot.width / 2
        origin.y: cardRoot.height / 2
        axis { x: 0; y: 1; z: 0 }
        angle: 0
    }

    // Drop shadow
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.leftMargin: 2
        radius: 6
        color: "#40000000"
    }

    // Card face
    Rectangle {
        id: cardFace
        anchors.fill: parent
        radius: 6
        color: root.cardWhite
        border.color: highlighted ? root.goldBright : "#30000000"
        border.width: highlighted ? 2 : 0.5
        visible: faceUp

        // Subtle texture gradient
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 5
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#faf8f0" }
                GradientStop { position: 1.0; color: "#f0ead8" }
            }
        }

        // Top-left corner
        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 4
            anchors.leftMargin: 5
            spacing: -4

            Text {
                text: cardRoot.rankStr
                font.family: root.displayFont
                font.pixelSize: 16
                font.bold: true
                color: cardRoot.isRed ? root.cardRed : "#1a1a1a"
            }
            Text {
                text: cardRoot.suitStr
                font.pixelSize: 12
                color: cardRoot.isRed ? root.cardRed : "#1a1a1a"
            }
        }

        // Center suit (large)
        Text {
            anchors.centerIn: parent
            text: cardRoot.suitStr
            font.pixelSize: 28
            color: cardRoot.isRed ? root.cardRed : "#2a2a2a"
            opacity: 0.6
        }

        // Bottom-right corner (rotated)
        Column {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 4
            anchors.rightMargin: 5
            spacing: -4
            rotation: 180
            transformOrigin: Item.Center

            Text {
                text: cardRoot.rankStr
                font.family: root.displayFont
                font.pixelSize: 16
                font.bold: true
                color: cardRoot.isRed ? root.cardRed : "#1a1a1a"
            }
            Text {
                text: cardRoot.suitStr
                font.pixelSize: 12
                color: cardRoot.isRed ? root.cardRed : "#1a1a1a"
            }
        }

        // Highlight glow
        Rectangle {
            anchors.fill: parent
            radius: 6
            color: root.goldBright
            opacity: highlighted ? 0.15 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // Card back
    Rectangle {
        id: cardBack
        anchors.fill: parent
        radius: 6
        color: "#1a2b5e"
        border.color: root.goldAccent
        border.width: 1
        visible: !faceUp

        // Outer filigree frame
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 4
            color: "transparent"
            border.color: root.goldBright
            border.width: 0.5
            opacity: 0.55
        }
        // Middle frame
        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: 3
            color: "transparent"
            border.color: root.goldAccent
            border.width: 0.5
            opacity: 0.45
        }
        // Inner frame
        Rectangle {
            anchors.fill: parent
            anchors.margins: 9
            radius: 2
            color: "transparent"
            border.color: root.goldDim
            border.width: 0.5
            opacity: 0.35
        }

        // Corner diamonds
        Text { anchors.top: parent.top; anchors.left: parent.left
               anchors.margins: 4; text: "◆"; font.pixelSize: 5
               color: root.goldAccent; opacity: 0.7 }
        Text { anchors.top: parent.top; anchors.right: parent.right
               anchors.margins: 4; text: "◆"; font.pixelSize: 5
               color: root.goldAccent; opacity: 0.7 }
        Text { anchors.bottom: parent.bottom; anchors.left: parent.left
               anchors.margins: 4; text: "◆"; font.pixelSize: 5
               color: root.goldAccent; opacity: 0.7 }
        Text { anchors.bottom: parent.bottom; anchors.right: parent.right
               anchors.margins: 4; text: "◆"; font.pixelSize: 5
               color: root.goldAccent; opacity: 0.7 }

        // Centre fleur-de-lis
        Text {
            anchors.centerIn: parent
            text: "⚜"
            font.pixelSize: 22
            color: root.goldAccent
            opacity: 0.65
        }
    }

    // Dim overlay for dead cards
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "#80000000"
        visible: dimmed
    }

    opacity: dimmed ? 0.4 : 1.0
    Behavior on opacity { NumberAnimation { duration: 300 } }
}
