import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Faro.Engine 1.0

Item {
    id: gameRoot

    required property GameEngine engine
    signal gameFinished()
    signal backToTitle()

    property int selectedBetAmount: 5
    property bool contreMode: false

    // ── Auto-advance after result display ──
    Timer {
        id: autoAdvanceTimer
        interval: 3000
        repeat: false
        onTriggered: {
            engine.nextBettingRound()
            if (engine.gameState === GameEngine.GameOver)
                gameRoot.gameFinished()
        }
    }

    Connections {
        target: engine
        function onGameStateChanged() {
            if (engine.gameState === GameEngine.TurnResult)
                autoAdvanceTimer.restart()
            else
                autoAdvanceTimer.stop()
        }
    }

    // ── Top bar: turn info & chips ──
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "#22080408"
        border.color: root.goldDim
        border.width: 0
        // Bottom separator line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: root.goldDim
            opacity: 0.3
        }
        z: 20

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 24

            // Back button
            Text {
                text: "◂ QUITTER"
                font.family: root.bodyFont
                font.pixelSize: 12
                font.letterSpacing: 2
                color: root.goldDim
                opacity: 0.7
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gameRoot.backToTitle()
                    ToolTip.visible: containsMouse
                    ToolTip.text: "Return to the title screen"
                    ToolTip.delay: 600
                }
            }

            Text {
                text: "DONNE " + engine.turnNumber + " / 25"
                font.family: root.monoFont
                font.pixelSize: 14
                color: root.goldAccent
                font.letterSpacing: 2
            }

            Item { Layout.fillWidth: true }

            // Cards remaining
            Row {
                spacing: 8
                Text {
                    text: "TALON"
                    font.family: root.bodyFont
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    color: root.goldDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: engine.cardsRemaining
                    font.family: root.monoFont
                    font.pixelSize: 18
                    font.bold: true
                    color: root.ivoryWhite
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: 1; height: 24; color: root.goldDim; opacity: 0.3 }

            // Player chips
            Row {
                spacing: 8
                Text {
                    text: "♦"
                    font.pixelSize: 18
                    color: root.goldBright
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: engine.playerChips
                    font.family: root.monoFont
                    font.pixelSize: 22
                    font.bold: true
                    color: root.goldBright
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: 1; height: 24; color: root.goldDim; opacity: 0.3 }

            // Help button
            Rectangle {
                width: 28; height: 28; radius: 14
                color: "transparent"
                border.color: root.goldDim
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "?"
                    font.family: root.bodyFont
                    font.pixelSize: 14
                    font.bold: true
                    color: root.goldDim
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: helpOverlay.visible = true
                    ToolTip.visible: containsMouse
                    ToolTip.text: "Show game rules and glossary"
                    ToolTip.delay: 400
                }
            }
        }
    }

    // ── Main game area ──
    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 60
        anchors.margins: 16
        spacing: 16

        // ── Left: Tableau ──
        CaseKeeper {
            id: caseKeeperPanel
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            engine: gameRoot.engine
        }

        // ── Center: Faro Table ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Felt table surface
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 16
                color: root.feltGreen
                border.color: root.goldAccent
                border.width: 3

                // Inner felt gradient
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 13
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#245c38" }
                        GradientStop { position: 0.5; color: root.feltGreen }
                        GradientStop { position: 1.0; color: root.feltDark }
                    }
                }

                // Outer bright gold highlight line
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 15
                    color: "transparent"
                    border.color: root.goldBright
                    border.width: 0.5
                    opacity: 0.35
                }
                // First inner ornamental frame
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 7
                    radius: 11
                    color: "transparent"
                    border.color: root.goldAccent
                    border.width: 1
                    opacity: 0.45
                }
                // Second inner ornamental frame
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 11
                    radius: 8
                    color: "transparent"
                    border.color: root.goldDim
                    border.width: 0.5
                    opacity: 0.3
                }

                // ── Faro layout: 13 card positions ──
                FaroTable {
                    id: faroTable
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -20
                    width: Math.min(parent.width - 40, 700)
                    height: Math.min(parent.height - 200, 400)
                    engine: gameRoot.engine
                    betAmount: gameRoot.selectedBetAmount
                    contre: gameRoot.contreMode
                    enabled: engine.gameState === GameEngine.Betting
                }

                // ── Dealer area: soda, loser, winner ──
                DealerBox {
                    id: dealerBox
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 400
                    height: 140
                    engine: gameRoot.engine
                }
            }
        }

        // ── Right: Controls ──
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            radius: 12
            color: "#1a08040c"
            border.color: root.goldAccent
            border.width: 1

            // Inner ornamental border
            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: 10
                color: "transparent"
                border.color: root.goldDim
                border.width: 0.5
                opacity: 0.4
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 0

                // ── Wager label ──
                Text {
                    text: "MISE"
                    font.family: root.bodyFont
                    font.pixelSize: 11
                    font.letterSpacing: 3
                    color: root.goldDim
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 8 }

                // Bet chip row
                Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignHCenter
                    Repeater {
                        model: [1, 5, 10, 25]
                        Rectangle {
                            width: 40; height: 36
                            radius: 6
                            color: gameRoot.selectedBetAmount === modelData ? root.goldAccent : "#30ffffff"
                            border.color: root.goldDim
                            border.width: 0.5

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: root.monoFont
                                font.pixelSize: 13
                                font.bold: true
                                color: gameRoot.selectedBetAmount === modelData ? root.shadowBlack : root.ivoryWhite
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: gameRoot.selectedBetAmount = modelData
                                ToolTip.visible: containsMouse
                                ToolTip.text: "Set wager to " + modelData + " jeton" + (modelData > 1 ? "s" : "")
                                ToolTip.delay: 600
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 10 }

                // CONTRE toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: gameRoot.contreMode ? root.copperAccent : "#20ffffff"
                    border.color: gameRoot.contreMode ? root.copperAccent : root.goldDim
                    border.width: 0.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: root.copperAccent
                            border.color: "#60000000"
                            border.width: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "CONTRE"
                            font.family: root.bodyFont
                            font.pixelSize: 11
                            font.letterSpacing: 2
                            color: gameRoot.contreMode ? root.shadowBlack : root.ivoryWhite
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gameRoot.contreMode = !gameRoot.contreMode
                        ToolTip.visible: containsMouse
                        ToolTip.text: "Invert your bet — win when the card loses"
                        ToolTip.delay: 600
                    }

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 10 }

                Rectangle { Layout.fillWidth: true; height: 1; color: root.goldDim; opacity: 0.2 }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 10 }

                // CARTE HAUTE
                Rectangle {
                    id: carteHauteBtn
                    Layout.fillWidth: true
                    height: 40
                    radius: 6

                    readonly property var highCardBet: engine.currentBets ? engine.currentBets["cartehaute"] : null
                    readonly property bool highCardActive: highCardBet !== undefined && highCardBet !== null
                    readonly property bool inBetting: engine.gameState === GameEngine.Betting

                    color: highCardActive ? root.goldAccent : "#20ffffff"
                    border.color: highCardActive ? root.goldBright : root.goldDim
                    border.width: highCardActive ? 1 : 0.5
                    opacity: inBetting ? 1.0 : 0.3
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "CARTE HAUTE"
                            font.family: root.bodyFont
                            font.pixelSize: 11
                            font.letterSpacing: 2
                            color: carteHauteBtn.highCardActive ? root.shadowBlack : root.goldAccent
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: carteHauteBtn.highCardActive ? 0.75 : 0.0
                            text: {
                                if (!carteHauteBtn.highCardBet) return " "
                                var amt = carteHauteBtn.highCardBet["amount"] || 0
                                var cop = carteHauteBtn.highCardBet["contre"] || false
                                return (cop ? "✦ " : "") + amt + " jeton" + (amt !== 1 ? "s" : "")
                            }
                            font.family: root.monoFont
                            font.pixelSize: 9
                            color: root.shadowBlack
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: carteHauteBtn.inBetting
                        hoverEnabled: carteHauteBtn.inBetting
                        cursorShape: carteHauteBtn.inBetting ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: engine.placeHighCardBet(gameRoot.selectedBetAmount, gameRoot.contreMode)
                        ToolTip.visible: containsMouse
                        ToolTip.text: "Bet that the winner card will outrank the loser card"
                        ToolTip.delay: 600
                    }
                }

                // ── Flexible gap above DONNER ──
                Item { Layout.fillWidth: true; Layout.fillHeight: true }

                // DONNER — the single action button
                Rectangle {
                    id: donnerBtn
                    Layout.fillWidth: true
                    height: 52
                    radius: 8

                    readonly property bool isActive: engine.gameState === GameEngine.Betting

                    gradient: Gradient {
                        GradientStop { position: 0; color: donnerBtn.isActive ? root.goldAccent : "#22ffffff" }
                        GradientStop { position: 1; color: donnerBtn.isActive ? root.goldDim    : "#14ffffff" }
                    }
                    opacity: donnerBtn.isActive ? 1.0 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    Text {
                        anchors.centerIn: parent
                        text: "DONNER"
                        font.family: root.bodyFont
                        font.pixelSize: 14
                        font.letterSpacing: 3
                        font.bold: true
                        color: donnerBtn.isActive ? root.shadowBlack : root.goldDim
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: donnerBtn.isActive
                        hoverEnabled: donnerBtn.isActive
                        cursorShape: donnerBtn.isActive ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: { engine.confirmBets(); engine.dealTurn() }
                        ToolTip.visible: containsMouse
                        ToolTip.text: "Confirm all bets and deal the next two cards"
                        ToolTip.delay: 600
                    }
                }

                // ── Flexible gap below DONNER ──
                Item { Layout.fillWidth: true; Layout.fillHeight: true }

                // ── Résultat de la donne ──
                Rectangle {
                    id: resultPanel
                    Layout.fillWidth: true
                    height: 148
                    radius: 8
                    color: "#1c08050f"
                    border.color: root.goldDim
                    border.width: 0.5
                    clip: true
                    opacity: engine.turnResultText.length > 0 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 350 } }

                    // Restart countdown bar whenever a new result arrives
                    Connections {
                        target: engine
                        function onTurnResultTextChanged() {
                            if (engine.turnResultText.length > 0)
                                countdownAnim.restart()
                        }
                    }

                    Column {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 5

                        // Header
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "RÉSULTAT DE LA DONNE"
                            font.family: root.bodyFont
                            font.pixelSize: 8
                            font.letterSpacing: 2
                            color: root.goldDim
                        }

                        // Cards dealt
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            visible: engine.loserCard !== null && engine.winnerCard !== null

                            Text {
                                text: {
                                    if (!engine.loserCard) return ""
                                    var rn = ["","A","2","3","4","5","6","7","8","9","10","V","D","R"]
                                    var ss = ["♠","♥","♦","♣"]
                                    return rn[engine.loserCard.rank] + ss[engine.loserCard.suit]
                                }
                                font.family: root.monoFont; font.pixelSize: 17; font.bold: true
                                color: engine.loserCard && (engine.loserCard.suit === 1 || engine.loserCard.suit === 2)
                                       ? root.cardRed : root.ivoryWhite
                            }
                            Text {
                                text: "›"
                                font.family: root.displayFont; font.pixelSize: 14
                                color: root.goldDim
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: {
                                    if (!engine.winnerCard) return ""
                                    var rn = ["","A","2","3","4","5","6","7","8","9","10","V","D","R"]
                                    var ss = ["♠","♥","♦","♣"]
                                    return rn[engine.winnerCard.rank] + ss[engine.winnerCard.suit]
                                }
                                font.family: root.monoFont; font.pixelSize: 17; font.bold: true
                                color: engine.winnerCard && (engine.winnerCard.suit === 1 || engine.winnerCard.suit === 2)
                                       ? root.cardRed : root.ivoryWhite
                            }
                        }

                        // Doublet notice
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: engine.loserCard && engine.winnerCard
                                     && engine.loserCard.rank === engine.winnerCard.rank
                            text: "✦ DOUBLET ✦"
                            font.family: root.bodyFont; font.pixelSize: 9; font.letterSpacing: 2
                            color: root.copperAccent
                        }

                        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }

                        // Per-bet breakdown
                        Text {
                            width: parent.width
                            text: engine.turnResultText
                            font.family: root.monoFont
                            font.pixelSize: 10
                            color: root.ivoryWhite
                            opacity: 0.85
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }

                        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }

                        // Net
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Text {
                                text: "NET"
                                font.family: root.bodyFont; font.pixelSize: 9; font.letterSpacing: 2
                                color: root.goldDim
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: (engine.lastWinAmount > 0 ? "+" : "") + engine.lastWinAmount + " jetons"
                                font.family: root.monoFont; font.pixelSize: 14; font.bold: true
                                color: engine.lastWinAmount > 0 ? root.winGreen
                                     : engine.lastWinAmount < 0 ? root.cardRed
                                     : root.goldDim
                            }
                        }
                    }

                    // Auto-advance countdown bar
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 3
                        color: root.goldDim
                        opacity: 0.25

                        Rectangle {
                            id: countdownBar
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            radius: 1
                            color: root.goldAccent
                            opacity: 0.7
                            width: parent.width

                            NumberAnimation on width {
                                id: countdownAnim
                                from: countdownBar.parent.width
                                to: 0
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 6 }

                // Instructions hint
                Text {
                    Layout.fillWidth: true
                    text: engine.gameState === GameEngine.Betting
                          ? "Placez vos mises sur le tableau"
                          : " "
                    font.family: root.bodyFont
                    font.pixelSize: 11
                    font.italic: true
                    color: root.goldDim
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // ── Help overlay ──
    Rectangle {
        id: helpOverlay
        anchors.fill: parent
        color: "#d0080508"
        visible: false
        z: 200

        // Dismiss on background click
        MouseArea {
            anchors.fill: parent
            onClicked: helpOverlay.visible = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 640)
            height: Math.min(parent.height - 80, 640)
            radius: 12
            color: "#f01c0e18"
            border.color: root.goldAccent
            border.width: 1

            // Inner border
            Rectangle {
                anchors.fill: parent; anchors.margins: 3
                radius: 10; color: "transparent"
                border.color: root.goldDim; border.width: 0.5; opacity: 0.5
            }

            // Absorb clicks so background dismiss doesn't fire
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 0

                // Header
                Row {
                    width: parent.width

                    Text {
                        text: "HOW TO PLAY PHARAON"
                        font.family: root.displayFont
                        font.pixelSize: 22
                        font.letterSpacing: 4
                        color: root.goldAccent
                        width: parent.width - 36
                    }

                    // Close button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: "transparent"
                        border.color: root.goldDim
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 12
                            color: root.goldDim
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: helpOverlay.visible = false
                        }
                    }
                }

                Item { width: 1; height: 12 }
                Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.3 }
                Item { width: 1; height: 14 }

                // Scrollable content
                Flickable {
                    width: parent.width
                    height: parent.height - 60
                    contentHeight: helpContent.height
                    clip: true

                    Column {
                        id: helpContent
                        width: parent.width
                        spacing: 10

                        Text {
                            width: parent.width
                            text: "Pharaon is a 17th-century French card game of pure chance. " +
                                  "You bet on which card rank will appear as the winner (gagnant) " +
                                  "or loser (perdant) each round. The banker draws two cards — " +
                                  "the first wins for the bank, the second wins for you."
                            font.family: root.bodyFont
                            font.pixelSize: 13
                            color: root.ivoryWhite
                            opacity: 0.85
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        Item { width: 1; height: 4 }

                        Text {
                            text: "THE DEAL"
                            font.family: root.bodyFont
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            color: root.goldDim
                        }

                        Text {
                            width: parent.width
                            text: "Each round (donne), two cards are drawn from the deck (talon). " +
                                  "The first card drawn loses — the bank collects bets on it. " +
                                  "The second card drawn wins — you collect bets on it. " +
                                  "If both cards share the same rank, it is a doublet: the bank takes half your bet."
                            font.family: root.bodyFont
                            font.pixelSize: 13
                            color: root.ivoryWhite
                            opacity: 0.85
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        Item { width: 1; height: 4 }

                        Text {
                            text: "BETTING"
                            font.family: root.bodyFont
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            color: root.goldDim
                        }

                        Text {
                            width: parent.width
                            text: "Click any card on the table to place a bet on that rank. " +
                                  "Click again to remove it. A bet carries over to the next round if that rank was not drawn. " +
                                  "Activate CONTRE to invert your bet — you win when the card appears as the loser instead of the winner. " +
                                  "CARTE HAUTE bets that the winner card will outrank the loser card."
                            font.family: root.bodyFont
                            font.pixelSize: 13
                            color: root.ivoryWhite
                            opacity: 0.85
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        Item { width: 1; height: 4 }

                        Text {
                            text: "LAST THREE (TROIS DERNIÈRES)"
                            font.family: root.bodyFont
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            color: root.goldDim
                        }

                        Text {
                            width: parent.width
                            text: "When three cards remain, you may predict the exact order they will appear. " +
                                  "A correct prediction pays 4× your bet (2× if there is a doublet among the three). " +
                                  "The last card of all (l'écart) belongs to the bank and is never in play."
                            font.family: root.bodyFont
                            font.pixelSize: 13
                            color: root.ivoryWhite
                            opacity: 0.85
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }

                        Item { width: 1; height: 12 }
                        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.25 }
                        Item { width: 1; height: 12 }

                        Text {
                            text: "FRENCH GLOSSARY"
                            font.family: root.bodyFont
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            color: root.goldDim
                        }

                        Item { width: 1; height: 4 }

                        // Glossary entries
                        Repeater {
                            model: [
                                { term: "Pharaon",        def: "The game itself — the French name, later corrupted to 'Faro'" },
                                { term: "La donne",       def: "One round of play (a deal of two cards)" },
                                { term: "La souche",      def: "The first card drawn at game start — shown face-up before betting begins; the bank keeps it" },
                                { term: "Le talon",       def: "The remaining deck of cards" },
                                { term: "Le perdant",     def: "The first card drawn in a round — loses for the player, wins for the bank" },
                                { term: "Le gagnant",     def: "The second card drawn in a round — wins for the player" },
                                { term: "Le doublet",     def: "When both drawn cards share the same rank — the bank takes half the bet" },
                                { term: "À contre",       def: "A bet placed in reverse — win when the card appears as the loser" },
                                { term: "Carte haute",    def: "A bet that the winner card will outrank the loser card in that round" },
                                { term: "L'écart",        def: "The very last card — shown but not in play; it belongs to the bank" },
                                { term: "Le tableau",     def: "The tracking board showing which cards of each rank have appeared" },
                                { term: "La mise",        def: "Your wager (bet amount)" },
                                { term: "Les jetons",     def: "Chips / tokens used for wagering" },
                                { term: "La banque",      def: "The banker — your opponent, who deals and collects losing bets" }
                            ]

                            Row {
                                width: helpContent.width
                                spacing: 12

                                Text {
                                    width: 130
                                    text: modelData.term
                                    font.family: root.bodyFont
                                    font.pixelSize: 13
                                    font.italic: true
                                    color: root.goldAccent
                                }

                                Text {
                                    width: parent.width - 142
                                    text: modelData.def
                                    font.family: root.bodyFont
                                    font.pixelSize: 12
                                    color: root.ivoryWhite
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.35
                                }
                            }
                        }

                        Item { width: 1; height: 20 }
                    }
                }
            }
        }

        // Fade in
        NumberAnimation on opacity {
            running: helpOverlay.visible
            from: 0; to: 1; duration: 250
            easing.type: Easing.OutCubic
        }
    }

    // ── Win/Loss flash overlay ──
    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        color: "transparent"
        opacity: 0
        z: 80

        Connections {
            target: engine
            function onPlayerWon(amount) {
                flashOverlay.color = "#40d4a843"
                flashAnim.running = true
            }
            function onPlayerLost(amount) {
                flashOverlay.color = "#409b1b1b"
                flashAnim.running = true
            }
            function onDoubletOccurred(rank) {
                flashOverlay.color = "#40b87333"
                flashAnim.running = true
            }
        }

        SequentialAnimation {
            id: flashAnim
            NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.6; duration: 100 }
            NumberAnimation { target: flashOverlay; property: "opacity"; to: 0; duration: 600; easing.type: Easing.OutCubic }
        }
    }
}
