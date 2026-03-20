import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Faro.Engine 1.0

Item {
    id: gameRoot

    required property GameEngine engine
    signal gameFinished()
    signal backToTitle()

    property int  selectedBetAmount: 5
    property bool contreMode:        false

    // ── Object pools for flying animations ────────────────────────────────────
    property var _cardPool: []
    property var _chipPool: []

    Component { id: flyingCardComp; FlyingCard {} }
    Component { id: flyingChipComp; FlyingChip {} }

    Component.onCompleted: {
        for (var i = 0; i < 2; i++)
            _cardPool.push(flyingCardComp.createObject(flyingCardLayer, {visible: false}))
        for (var j = 0; j < 8; j++)
            _chipPool.push(flyingChipComp.createObject(flyingChipLayer, {visible: false}))
    }

    function acquireCard() {
        for (var i = 0; i < _cardPool.length; i++)
            if (!_cardPool[i].visible) return _cardPool[i]
        var o = flyingCardComp.createObject(flyingCardLayer, {visible: false})
        _cardPool.push(o)
        return o
    }

    function acquireChip() {
        for (var i = 0; i < _chipPool.length; i++)
            if (!_chipPool[i].visible) return _chipPool[i]
        var o = flyingChipComp.createObject(flyingChipLayer, {visible: false})
        _chipPool.push(o)
        return o
    }

    Connections {
        target: engine
        function onGameStateChanged() {
            if (engine.gameState === GameEngine.GameOver)
                gameRoot.gameFinished()
        }
    }

    // ── Top bar ───────────────────────────────────────────────────────────────
    Rectangle {
        id: topBar
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 60
        color: "#22080408"
        z: 20

        // Bottom separator line
        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 1; color: root.goldDim; opacity: 0.3
        }

        // ── Betting timer bar ──────────────────────────────────────────────
        Rectangle {
            id: timerBarBg
            anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right
            height: 3
            color: root.goldDim; opacity: 0.15
            visible: engine.gameState === GameEngine.Betting

            Rectangle {
                id: timerBar
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
                radius: 1
                width: engine.bettingTimeMs > 0
                       ? parent.width * (engine.bettingTimerRemaining / engine.bettingTimeMs)
                       : 0
                color: (engine.bettingTimerRemaining / engine.bettingTimeMs) < 0.2
                       ? root.copperAccent : root.goldAccent
                opacity: 0.75
                Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 24

            // Back button
            Text {
                text: "◂ QUITTER"
                font.family: root.bodyFont; font.pixelSize: 12; font.letterSpacing: 2
                color: root.goldDim; opacity: 0.7
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: gameRoot.backToTitle()
                    ToolTip.visible: containsMouse; ToolTip.text: "Return to the title screen"; ToolTip.delay: 600
                }
            }

            Text {
                text: "DONNE " + engine.turnNumber + " / 25"
                font.family: root.monoFont; font.pixelSize: 14; color: root.goldAccent; font.letterSpacing: 2
            }

            Item { Layout.fillWidth: true }

            // Cards remaining
            Row {
                spacing: 8
                Text { text: "TALON"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 2; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
                Text { text: engine.cardsRemaining; font.family: root.monoFont; font.pixelSize: 18; font.bold: true; color: root.ivoryWhite; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle { width: 1; height: 24; color: root.goldDim; opacity: 0.3 }

            // Bank balance
            Row {
                spacing: 6
                Text { text: "LA BANQUE"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 2; color: root.copperAccent; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    id: bankLabel
                    text: "♣ " + engine.bankerChips
                    font.family: root.monoFont; font.pixelSize: 14; font.bold: true
                    color: root.copperAccent; anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: 1; height: 24; color: root.goldDim; opacity: 0.3 }

            // Player chips
            Row {
                spacing: 8
                Text { text: "♦"; font.pixelSize: 18; color: root.goldBright; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    id: playerChipsLabel
                    text: engine.playerChips
                    font.family: root.monoFont; font.pixelSize: 22; font.bold: true
                    color: root.goldBright; anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: 1; height: 24; color: root.goldDim; opacity: 0.3 }

            // Help button
            Rectangle {
                width: 28; height: 28; radius: 14; color: "transparent"
                border.color: root.goldDim; border.width: 1; anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "?"; font.family: root.bodyFont; font.pixelSize: 14; font.bold: true; color: root.goldDim }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: helpOverlay.visible = true
                    ToolTip.visible: containsMouse; ToolTip.text: "Show game rules and glossary"; ToolTip.delay: 400
                }
            }
        }
    }

    // ── Player tray (bottom strip) ────────────────────────────────────────────
    PlayerTray {
        id: playerTray
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        engine: gameRoot.engine
        visible: engine.players.length > 1
    }

    // Helper: map a seat's purse center into flyingChipLayer coordinates
    function getPurseCenter(seatIndex) {
        var pt = playerTray.purseCenter(seatIndex)
        return playerTray.mapToItem(flyingChipLayer, pt.x, pt.y)
    }

    // ── Main game area ────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 60
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: (engine.players.length > 1 ? playerTray.height : 0) + 16
        spacing: 16

        // ── Left: Tableau ─────────────────────────────────────────────────────
        CaseKeeper {
            id: caseKeeperPanel
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            engine: gameRoot.engine
        }

        // ── Center: Faro Table ────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent; anchors.margins: 8; radius: 16
                color: root.feltGreen; border.color: root.goldAccent; border.width: 3

                Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 13
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#245c38" }
                        GradientStop { position: 0.5; color: root.feltGreen }
                        GradientStop { position: 1.0; color: root.feltDark }
                    }
                }
                Rectangle { anchors.fill: parent; anchors.margins: 1; radius: 15; color: "transparent"; border.color: root.goldBright; border.width: 0.5; opacity: 0.35 }
                Rectangle { anchors.fill: parent; anchors.margins: 7; radius: 11; color: "transparent"; border.color: root.goldAccent; border.width: 1; opacity: 0.45 }
                Rectangle { anchors.fill: parent; anchors.margins: 11; radius: 8; color: "transparent"; border.color: root.goldDim; border.width: 0.5; opacity: 0.3 }

                FaroTable {
                    id: faroTable
                    anchors.centerIn: parent; anchors.verticalCenterOffset: -20
                    width: Math.min(parent.width - 40, 700)
                    height: Math.min(parent.height - 200, 400)
                    engine: gameRoot.engine
                    betAmount: gameRoot.selectedBetAmount
                    contre: gameRoot.contreMode
                    enabled: engine.gameState !== GameEngine.GameOver
                }

                DealerBox {
                    id: dealerBox
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 400; height: 140
                    engine: gameRoot.engine
                }
            }

            // ── Flying card / chip layer ───────────────────────────────────────
            Item { id: flyingCardLayer; anchors.fill: parent; z: 50 }
            Item { id: flyingChipLayer; anchors.fill: parent; z: 51 }
        }

        // ── Right: Controls ───────────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            radius: 12; color: "#1a08040c"
            border.color: root.goldAccent; border.width: 1

            Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 10; color: "transparent"; border.color: root.goldDim; border.width: 0.5; opacity: 0.4 }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 0

                // MISE label
                Text { text: "MISE"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3; color: root.goldDim }
                Item { Layout.fillWidth: true; Layout.preferredHeight: 8 }

                // Bet chip row
                Row {
                    spacing: 6; Layout.alignment: Qt.AlignHCenter
                    Repeater {
                        model: [1, 5, 10, 25]
                        Rectangle {
                            id: betChipBtn
                            width: 40; height: 36; radius: 6
                            color: gameRoot.selectedBetAmount === modelData ? root.goldAccent : "#30ffffff"
                            border.color: root.goldDim; border.width: 0.5
                            Text {
                                anchors.centerIn: parent; text: modelData
                                font.family: root.monoFont; font.pixelSize: 13; font.bold: true
                                color: gameRoot.selectedBetAmount === modelData ? root.shadowBlack : root.ivoryWhite
                            }
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                    Layout.fillWidth: true; height: 40; radius: 6
                    color: gameRoot.contreMode ? root.copperAccent : "#20ffffff"
                    border.color: gameRoot.contreMode ? root.copperAccent : root.goldDim; border.width: 0.5
                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Rectangle { width: 14; height: 14; radius: 7; color: root.copperAccent; border.color: "#60000000"; border.width: 0.5; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "CONTRE"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 2; color: gameRoot.contreMode ? root.shadowBlack : root.ivoryWhite; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: gameRoot.contreMode = !gameRoot.contreMode
                        ToolTip.visible: containsMouse; ToolTip.text: "Invert your bet — win when the card loses"; ToolTip.delay: 600
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 10 }
                Rectangle { Layout.fillWidth: true; height: 1; color: root.goldDim; opacity: 0.2 }
                Item { Layout.fillWidth: true; Layout.preferredHeight: 10 }

                // CARTE HAUTE
                Rectangle {
                    id: carteHauteBtn
                    Layout.fillWidth: true; height: 40; radius: 6
                    readonly property var  highCardBet:    engine.currentBets ? engine.currentBets["cartehaute"] : null
                    readonly property bool highCardActive: highCardBet !== undefined && highCardBet !== null
                    readonly property bool inBetting:      engine.gameState === GameEngine.Betting
                    color: highCardActive ? root.goldAccent : "#20ffffff"
                    border.color: highCardActive ? root.goldBright : root.goldDim
                    border.width: highCardActive ? 1 : 0.5
                    opacity: inBetting ? 1.0 : 0.3
                    Behavior on color   { ColorAnimation  { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter; text: "CARTE HAUTE"
                            font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 2
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
                            font.family: root.monoFont; font.pixelSize: 9; color: root.shadowBlack
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; enabled: carteHauteBtn.inBetting
                        hoverEnabled: carteHauteBtn.inBetting
                        cursorShape: carteHauteBtn.inBetting ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: engine.placeHighCardBet(gameRoot.selectedBetAmount, gameRoot.contreMode)
                        ToolTip.visible: containsMouse; ToolTip.text: "Bet that the winner card will outrank the loser card"; ToolTip.delay: 600
                    }
                }

                Item { Layout.fillWidth: true; Layout.fillHeight: true }

                // DONNER — hidden in autopilot mode
                Rectangle {
                    id: donnerBtn
                    Layout.fillWidth: true; height: 52; radius: 8
                    visible: !engine.autopilot
                    readonly property bool isActive: engine.gameState === GameEngine.Betting
                    gradient: Gradient {
                        GradientStop { position: 0; color: donnerBtn.isActive ? root.goldAccent : "#22ffffff" }
                        GradientStop { position: 1; color: donnerBtn.isActive ? root.goldDim    : "#14ffffff" }
                    }
                    opacity: donnerBtn.isActive ? 1.0 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Text {
                        anchors.centerIn: parent; text: "DONNER"
                        font.family: root.bodyFont; font.pixelSize: 14; font.letterSpacing: 3; font.bold: true
                        color: donnerBtn.isActive ? root.shadowBlack : root.goldDim
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                    MouseArea {
                        anchors.fill: parent; enabled: donnerBtn.isActive; hoverEnabled: donnerBtn.isActive
                        cursorShape: donnerBtn.isActive ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: { engine.confirmBets(); engine.dealTurn() }
                        ToolTip.visible: containsMouse; ToolTip.text: "Confirm all bets and deal the next two cards"; ToolTip.delay: 600
                    }
                }

                Item { Layout.fillWidth: true; Layout.fillHeight: true }

                // Result panel
                Rectangle {
                    id: resultPanel
                    Layout.fillWidth: true; height: 148; radius: 8
                    color: "#1c08050f"; border.color: root.goldDim; border.width: 0.5; clip: true
                    opacity: engine.turnResultText.length > 0 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 350 } }

                    Column {
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                        anchors.topMargin: 8; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 5

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter; text: "RÉSULTAT DE LA DONNE"
                            font.family: root.bodyFont; font.pixelSize: 8; font.letterSpacing: 2; color: root.goldDim
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                            visible: engine.loserCard !== null && engine.winnerCard !== null
                            Text {
                                text: {
                                    if (!engine.loserCard) return ""
                                    var rn = ["","A","2","3","4","5","6","7","8","9","10","V","D","R"]
                                    var ss = ["♠","♥","♦","♣"]
                                    return rn[engine.loserCard.rank] + ss[engine.loserCard.suit]
                                }
                                font.family: root.monoFont; font.pixelSize: 17; font.bold: true
                                color: engine.loserCard && (engine.loserCard.suit === 1 || engine.loserCard.suit === 2) ? root.cardRed : root.ivoryWhite
                            }
                            Text { text: "›"; font.family: root.displayFont; font.pixelSize: 14; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: {
                                    if (!engine.winnerCard) return ""
                                    var rn = ["","A","2","3","4","5","6","7","8","9","10","V","D","R"]
                                    var ss = ["♠","♥","♦","♣"]
                                    return rn[engine.winnerCard.rank] + ss[engine.winnerCard.suit]
                                }
                                font.family: root.monoFont; font.pixelSize: 17; font.bold: true
                                color: engine.winnerCard && (engine.winnerCard.suit === 1 || engine.winnerCard.suit === 2) ? root.cardRed : root.ivoryWhite
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: engine.loserCard && engine.winnerCard && engine.loserCard.rank === engine.winnerCard.rank
                            text: "✦ DOUBLET ✦"; font.family: root.bodyFont; font.pixelSize: 9; font.letterSpacing: 2; color: root.copperAccent
                        }
                        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }
                        Text {
                            width: parent.width; text: engine.turnResultText
                            font.family: root.monoFont; font.pixelSize: 10; color: root.ivoryWhite; opacity: 0.85
                            wrapMode: Text.WordWrap; lineHeight: 1.35
                        }
                        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.2 }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                            Text { text: "NET"; font.family: root.bodyFont; font.pixelSize: 9; font.letterSpacing: 2; color: root.goldDim; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: (engine.lastWinAmount > 0 ? "+" : "") + engine.lastWinAmount + " jetons"
                                font.family: root.monoFont; font.pixelSize: 14; font.bold: true
                                color: engine.lastWinAmount > 0 ? root.winGreen : engine.lastWinAmount < 0 ? root.cardRed : root.goldDim
                            }
                        }
                    }

                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 6 }

                Text {
                    Layout.fillWidth: true
                    text: engine.gameState === GameEngine.Betting ? "Placez vos mises sur le tableau" : " "
                    font.family: root.bodyFont; font.pixelSize: 11; font.italic: true
                    color: root.goldDim; opacity: 0.6; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // ── Flying card / chip animation handlers ─────────────────────────────────
    Connections {
        target: engine

        function onCardDealt(cardRank, cardSuit, isWinner) {
            // Map talon slot to flying card layer, then slot destination
            var talonPos  = dealerBox.talonSlot.mapToItem(flyingCardLayer,
                                dealerBox.talonSlot.width  / 2 - 35,
                                dealerBox.talonSlot.height / 2 - 50)
            var destSlot  = isWinner ? dealerBox.winnerSlot : dealerBox.loserSlot
            var destPos   = destSlot.mapToItem(flyingCardLayer,
                                destSlot.width  / 2 - 35,
                                destSlot.height / 2 - 50)

            var card = acquireCard()
            card.fromX = talonPos.x; card.fromY = talonPos.y
            card.toX = destPos.x; card.toY = destPos.y
            card.cardRank = cardRank; card.cardSuit = cardSuit
            card.visible = true
        }

        function onBetPlaced(seatIndex, rank, amount, contre) {
            if (seatIndex !== 0 || rank < 1) return
            // Chip flies from human purse in tray to table slot
            var slotPos = faroTable.slotCenter(rank)
            var slotPt  = faroTable.mapToItem(flyingChipLayer, slotPos.x - 18, slotPos.y - 18)
            var fromPt  = engine.players.length > 0
                          ? getPurseCenter(0)
                          : playerChipsLabel.mapToItem(flyingChipLayer, 0, 0)

            var chip = acquireChip()
            chip.fromX = fromPt.x; chip.fromY = fromPt.y
            chip.toX = slotPt.x; chip.toY = slotPt.y
            chip.amount = amount; chip.contre = contre; chip.isWin = false
            chip.visible = true
        }

        function onAiBetPlaced(seatIndex, rank, amount, contre) {
            if (rank < 1) return
            var slotPos = faroTable.slotCenter(rank)
            var slotPt  = faroTable.mapToItem(flyingChipLayer, slotPos.x - 9, slotPos.y - 9)
            // Fly from AI purse → table slot
            var fromPt  = engine.players.length > seatIndex
                          ? getPurseCenter(seatIndex)
                          : bankLabel.mapToItem(flyingChipLayer, 0, 0)

            var chip = acquireChip()
            chip.fromX = fromPt.x; chip.fromY = fromPt.y
            chip.toX = slotPt.x; chip.toY = slotPt.y
            chip.amount = amount; chip.contre = contre; chip.isWin = false
            chip.visible = true
        }

        function onBetWon(seatIndex, rank, amount) {
            if (rank < 1) return
            var slotPos = faroTable.slotCenter(rank)
            var slotPt  = faroTable.mapToItem(flyingChipLayer, slotPos.x - 18, slotPos.y - 18)
            var toPt    = engine.players.length > seatIndex
                          ? getPurseCenter(seatIndex)
                          : playerChipsLabel.mapToItem(flyingChipLayer, 0, 0)

            // Chip 1: bet chip from table slot → purse
            var chip1 = acquireChip()
            chip1.fromX = slotPt.x; chip1.fromY = slotPt.y
            chip1.toX = toPt.x; chip1.toY = toPt.y
            chip1.amount = amount; chip1.contre = false; chip1.isWin = true
            chip1.visible = true
            // Chip 2: winnings from bank → purse
            var bankPt = bankLabel.mapToItem(flyingChipLayer, 0, 0)
            var chip2 = acquireChip()
            chip2.fromX = bankPt.x; chip2.fromY = bankPt.y
            chip2.toX = toPt.x; chip2.toY = toPt.y
            chip2.amount = amount; chip2.contre = false; chip2.isWin = true
            chip2.visible = true
        }

        function onBetLost(seatIndex, rank, amount) {
            if (rank < 1) return
            var slotPos = faroTable.slotCenter(rank)
            var slotPt  = faroTable.mapToItem(flyingChipLayer, slotPos.x - 18, slotPos.y - 18)
            var toPt    = bankLabel.mapToItem(flyingChipLayer, 0, 0)

            var chip = acquireChip()
            chip.fromX = slotPt.x; chip.fromY = slotPt.y
            chip.toX = toPt.x; chip.toY = toPt.y
            chip.amount = amount; chip.contre = false; chip.isWin = false
            chip.visible = true
        }
    }

    // ── Help overlay ──────────────────────────────────────────────────────────
    Rectangle {
        id: helpOverlay
        anchors.fill: parent; color: "#d0080508"; visible: false; z: 200

        MouseArea { anchors.fill: parent; onClicked: helpOverlay.visible = false }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 640)
            height: Math.min(parent.height - 80, 640)
            radius: 12; color: "#f01c0e18"
            border.color: root.goldAccent; border.width: 1

            Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 10; color: "transparent"; border.color: root.goldDim; border.width: 0.5; opacity: 0.5 }
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent; anchors.margins: 24; spacing: 0

                Row {
                    width: parent.width
                    Text {
                        text: "HOW TO PLAY PHARAON"
                        font.family: root.displayFont; font.pixelSize: 22; font.letterSpacing: 4; color: root.goldAccent
                        width: parent.width - 36
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 14; color: "transparent"; border.color: root.goldDim; border.width: 1
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 12; color: root.goldDim }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: helpOverlay.visible = false }
                    }
                }

                Item { width: 1; height: 12 }
                Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.3 }
                Item { width: 1; height: 14 }

                Flickable {
                    width: parent.width; height: parent.height - 60
                    contentHeight: helpContent.height; clip: true

                    Column {
                        id: helpContent; width: parent.width; spacing: 10

                        Text { width: parent.width; text: "Pharaon is a 17th-century French card game of pure chance. You bet on which card rank will appear as the winner (gagnant) or loser (perdant) each round. The banker draws two cards — the first wins for the bank, the second wins for you."; font.family: root.bodyFont; font.pixelSize: 13; color: root.ivoryWhite; opacity: 0.85; wrapMode: Text.WordWrap; lineHeight: 1.4 }
                        Item { width: 1; height: 4 }
                        Text { text: "THE DEAL"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3; color: root.goldDim }
                        Text { width: parent.width; text: "Each round (donne), two cards are drawn from the deck (talon). The first card drawn loses — the bank collects bets on it. The second card drawn wins — you collect bets on it. If both cards share the same rank, it is a doublet: the bank takes half your bet."; font.family: root.bodyFont; font.pixelSize: 13; color: root.ivoryWhite; opacity: 0.85; wrapMode: Text.WordWrap; lineHeight: 1.4 }
                        Item { width: 1; height: 4 }
                        Text { text: "BETTING"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3; color: root.goldDim }
                        Text { width: parent.width; text: "Click any card on the table to place a bet on that rank. Click again to remove it. A bet carries over to the next round if that rank was not drawn. Activate CONTRE to invert your bet — you win when the card appears as the loser instead of the winner. CARTE HAUTE bets that the winner card will outrank the loser card."; font.family: root.bodyFont; font.pixelSize: 13; color: root.ivoryWhite; opacity: 0.85; wrapMode: Text.WordWrap; lineHeight: 1.4 }
                        Item { width: 1; height: 4 }
                        Text { text: "LAST THREE (TROIS DERNIÈRES)"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3; color: root.goldDim }
                        Text { width: parent.width; text: "When three cards remain, you may predict the exact order they will appear. A correct prediction pays 4× your bet (2× if there is a doublet among the three). The last card of all (l'écart) belongs to the bank and is never in play."; font.family: root.bodyFont; font.pixelSize: 13; color: root.ivoryWhite; opacity: 0.85; wrapMode: Text.WordWrap; lineHeight: 1.4 }
                        Item { width: 1; height: 12 }
                        Rectangle { width: parent.width; height: 1; color: root.goldDim; opacity: 0.25 }
                        Item { width: 1; height: 12 }
                        Text { text: "FRENCH GLOSSARY"; font.family: root.bodyFont; font.pixelSize: 11; font.letterSpacing: 3; color: root.goldDim }
                        Item { width: 1; height: 4 }

                        Repeater {
                            model: [
                                { term: "Pharaon",     def: "The game itself — the French name, later corrupted to 'Faro'" },
                                { term: "La donne",    def: "One round of play (a deal of two cards)" },
                                { term: "La souche",   def: "The first card dealt at game start — shown face-up before betting begins; the bank keeps it" },
                                { term: "Le talon",    def: "The remaining deck of cards" },
                                { term: "Le perdant",  def: "The first card drawn in a round — loses for the player, wins for the bank" },
                                { term: "Le gagnant",  def: "The second card drawn in a round — wins for the player" },
                                { term: "Le doublet",  def: "When both drawn cards share the same rank — the bank takes half the bet" },
                                { term: "À contre",    def: "A bet placed in reverse — win when the card appears as the loser" },
                                { term: "Carte haute", def: "A bet that the winner card will outrank the loser card in that round" },
                                { term: "L'écart",     def: "The very last card — shown but not in play; it belongs to the bank" },
                                { term: "Le tableau",  def: "The tracking board showing which cards of each rank have appeared" },
                                { term: "La mise",     def: "Your wager (bet amount)" },
                                { term: "Les jetons",  def: "Chips / tokens used for wagering" },
                                { term: "La banque",   def: "The banker — your opponent, who deals and collects losing bets" }
                            ]
                            Row {
                                width: helpContent.width; spacing: 12
                                Text { width: 130; text: modelData.term; font.family: root.bodyFont; font.pixelSize: 13; font.italic: true; color: root.goldAccent }
                                Text { width: parent.width - 142; text: modelData.def; font.family: root.bodyFont; font.pixelSize: 12; color: root.ivoryWhite; opacity: 0.8; wrapMode: Text.WordWrap; lineHeight: 1.35 }
                            }
                        }
                        Item { width: 1; height: 20 }
                    }
                }
            }
        }

        NumberAnimation on opacity { running: helpOverlay.visible; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
    }

    // ── Win/Loss flash overlay ────────────────────────────────────────────────
    Rectangle {
        id: flashOverlay
        anchors.fill: parent; color: "transparent"; opacity: 0; z: 80

        Connections {
            target: engine
            function onPlayerWon(seatIndex, amount)   { if (seatIndex === 0) { flashOverlay.color = "#40d4a843"; flashAnim.running = true } }
            function onPlayerLost(seatIndex, amount)  { if (seatIndex === 0) { flashOverlay.color = "#409b1b1b"; flashAnim.running = true } }
            function onDoubletOccurred(rank)           { flashOverlay.color = "#40b87333"; flashAnim.running = true }
        }

        SequentialAnimation {
            id: flashAnim
            NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.6; duration: 100 }
            NumberAnimation { target: flashOverlay; property: "opacity"; to: 0; duration: 600; easing.type: Easing.OutCubic }
        }
    }
}
