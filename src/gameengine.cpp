#include "gameengine.h"
#include "playermodel.h"
#include "aiplayer.h"
#include "appsettings.h"
#include <QDebug>
#include <QSettings>
#include <QDateTime>
#include <algorithm>

// ── seat colours (must match playermodel.cpp) ──────────────────────────────
static const char* kSeatColors[] = {
    "#c9a227", "#b0c4de", "#cd7f32", "#9370db", "#48c774"
};

// ── GameEngine ──────────────────────────────────────────────────────────────

GameEngine::GameEngine(QObject *parent)
    : QObject(parent)
{
    m_bettingTimer = new QTimer(this);
    m_bettingTimer->setSingleShot(true);
    connect(m_bettingTimer, &QTimer::timeout, this, &GameEngine::onBettingTimerFired);

    m_bettingTickTimer = new QTimer(this);
    m_bettingTickTimer->setInterval(100);
    connect(m_bettingTickTimer, &QTimer::timeout, this, &GameEngine::onBettingTickFired);

    // Load leaderboard from QSettings
    QSettings s("QtShowcase", "Pharaon");
    m_leaderboard = s.value("Pharaon/leaderboard").toList();
}

GameEngine::~GameEngine()
{
    qDeleteAll(m_deck);
    qDeleteAll(m_discardPile);
    delete m_sodaCard;
    delete m_loserCard;
    delete m_winnerCard;
}

// ── Property accessors ───────────────────────────────────────────────────────

int GameEngine::playerChips() const
{
    return m_players.isEmpty() ? 0 : m_players[0]->chips();
}

QVariantMap GameEngine::currentBets() const
{
    return m_players.isEmpty() ? QVariantMap() : m_players[0]->currentBets();
}

QVariantList GameEngine::playersVariant() const
{
    QVariantList list;
    for (PlayerModel* p : m_players) {
        list.append(QVariant::fromValue(static_cast<QObject*>(p)));
    }
    return list;
}

// ── State ────────────────────────────────────────────────────────────────────

void GameEngine::setGameState(int state)
{
    if (m_gameState != state) {
        m_gameState = state;
        emit gameStateChanged();
    }
}

// ── startNewGame ─────────────────────────────────────────────────────────────

void GameEngine::startNewGame(int startingChips, int aiCount)
{
    // --- cleanup ---
    stopBettingTimer();

    qDeleteAll(m_deck);       m_deck.clear();
    qDeleteAll(m_discardPile); m_discardPile.clear();

    delete m_sodaCard;   m_sodaCard   = nullptr;
    delete m_loserCard;  m_loserCard  = nullptr;
    delete m_winnerCard; m_winnerCard = nullptr;

    m_caseKeeperData.clear();
    m_turnNumber      = 0;
    m_turnResultText.clear();
    m_lastWinAmount   = 0;
    m_lastThreeBetAmount = 0;
    m_bankBrokenState = false;

    // --- read settings ---
    AppSettings* cfg = AppSettings::instance();
    m_bettingTimeMs  = cfg->bettingTimerMs();
    m_initialBankChips = 1000;
    m_bankerChips    = m_initialBankChips;

    if (aiCount < 0) aiCount = cfg->aiPlayerCount();

    // --- create players ---
    qDeleteAll(m_players);   m_players.clear();
    qDeleteAll(m_aiPlayers); m_aiPlayers.clear();

    // Seat 0: human
    PlayerModel* human = PlayerModel::createHuman(startingChips, 0, this);
    connect(human, &PlayerModel::currentBetsChanged, this, [this]() {
        emit currentBetsChanged();
        updateAllPlayerBets();
    });
    connect(human, &PlayerModel::chipsChanged, this, &GameEngine::playerChipsChanged);
    m_players.append(human);

    // AI seats 1..N
    static const char* aiNames[]    = {"I", "II", "III", "IV"};
    static const int   staggerLo[]  = {500,  900, 1300, 1700};
    static const int   staggerHi[]  = {900, 1300, 1700, 2100};
    for (int i = 0; i < qMin(aiCount, 4); ++i) {
        int seat = i + 1;
        auto* aiModel = PlayerModel::createAI(
            QString("JOUEUR IA %1").arg(aiNames[i]), startingChips, seat, this);
        connect(aiModel, &PlayerModel::chipsChanged, this, &GameEngine::playersChanged);
        connect(aiModel, &PlayerModel::isThinkingChanged, this, &GameEngine::playersChanged);
        m_players.append(aiModel);

        auto* ai = new AIPlayer(aiModel, staggerLo[i], staggerHi[i], this);
        connect(ai, &AIPlayer::betsReady, this, &GameEngine::onAIBetsReady);
        m_aiPlayers.append(ai);
    }
    emit playersChanged();

    // --- build deck ---
    buildDeck();
    shuffleDeck();

    m_sodaCard = m_deck.takeFirst();
    m_sodaCard->setFaceUp(true);
    QVariantMap sodaInfo; sodaInfo["suit"] = m_sodaCard->suit(); sodaInfo["type"] = "souche";
    m_caseKeeperData[m_sodaCard->rank()].append(sodaInfo);

    emit sodaCardChanged();
    emit cardsRemainingChanged();
    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnNumberChanged();
    emit currentBetsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();
    emit bankBrokenStateChanged();
    emit bettingTimeMsChanged();

    m_bettingPhase = true;
    emit bettingPhaseChanged();
    setGameState(Betting);

    startBettingTimer();
    startAIBetting();
}

// ── buildDeck / shuffleDeck ──────────────────────────────────────────────────

void GameEngine::buildDeck()
{
    for (int suit = Card::Spades; suit <= Card::Clubs; ++suit)
        for (int rank = Card::Ace; rank <= Card::King; ++rank)
            m_deck.append(new Card(rank, suit, this));
}

void GameEngine::shuffleDeck()
{
    auto* rng = QRandomGenerator::global();
    for (int i = m_deck.size() - 1; i > 0; --i) {
        int j = rng->bounded(i + 1);
        m_deck.swapItemsAt(i, j);
    }
}

// ── Betting timer ────────────────────────────────────────────────────────────

void GameEngine::startBettingTimer()
{
    m_bettingTimerRemaining = m_bettingTimeMs;
    m_bettingTimer->setInterval(m_bettingTimeMs);
    m_bettingTimer->start();
    m_bettingTickTimer->start();
    emit bettingTimerRemainingChanged();
}

void GameEngine::stopBettingTimer()
{
    m_bettingTimer->stop();
    m_bettingTickTimer->stop();
}

void GameEngine::onBettingTickFired()
{
    m_bettingTimerRemaining -= 100;
    if (m_bettingTimerRemaining < 0) m_bettingTimerRemaining = 0;
    emit bettingTimerRemainingChanged();
}

void GameEngine::onBettingTimerFired()
{
    m_bettingTickTimer->stop();
    m_bettingTimerRemaining = 0;
    emit bettingTimerRemainingChanged();

    if (!m_bettingPhase) return;

    // Stop all pending AI timers
    for (AIPlayer* ai : m_aiPlayers)
        ai->cancelBetting();

    // Check if anyone placed any bets
    bool anyBets = false;
    for (PlayerModel* p : m_players) {
        if (!p->currentBets().isEmpty()) { anyBets = true; break; }
    }

    if (!anyBets) {
        nextBettingRound();
    } else {
        confirmBets();
        dealTurn();
    }
}

// ── AI ────────────────────────────────────────────────────────────────────────

void GameEngine::startAIBetting()
{
    for (AIPlayer* ai : m_aiPlayers) {
        ai->startBettingPhase(m_caseKeeperData, m_deck.size(), m_bettingTimeMs);
    }
}

void GameEngine::onAIBetsReady(int seatIndex, QVariantMap bets)
{
    if (!m_bettingPhase) return;
    if (seatIndex < 0 || seatIndex >= m_players.size()) return;

    PlayerModel* player = m_players[seatIndex];

    // Validate bets against player's stack
    QVariantMap validated;
    int stack = player->chips();
    int used  = 0;
    for (auto it = bets.constBegin(); it != bets.constEnd(); ++it) {
        QVariantMap bet = it.value().toMap();
        int amount = bet["amount"].toInt();
        if (amount > 0 && (used + amount) <= stack) {
            validated[it.key()] = it.value();
            used += amount;
            // Also check rank not dead (cartehaute is always valid)
            if (it.key() != "cartehaute") {
                int rank = it.key().toInt();
                if (m_caseKeeperData.value(rank).size() >= 4)
                    validated.remove(it.key());
            }
        }
    }

    player->setCurrentBets(validated);
    updateAllPlayerBets();

    // Emit aiBetPlaced for each rank bet (for chip animations)
    for (auto it = validated.constBegin(); it != validated.constEnd(); ++it) {
        if (it.key() == "cartehaute") continue;
        QVariantMap bet = it.value().toMap();
        emit aiBetPlaced(seatIndex, it.key().toInt(),
                         bet["amount"].toInt(), bet["contre"].toBool());
    }
}

// ── placeBet / removeBet / placeHighCardBet ──────────────────────────────────

void GameEngine::setAutopilot(bool v)
{
    if (m_autopilot != v) {
        m_autopilot = v;
        emit autopilotChanged();
    }
}

void GameEngine::rejoinPlayer(int seatIndex)
{
    if (seatIndex < 0 || seatIndex >= m_players.size()) return;
    PlayerModel* p = m_players[seatIndex];
    if (p->chips() > 0) return;  // already active
    int cost = AppSettings::instance()->startingChips();
    if (m_bankerChips < cost) return;
    m_bankerChips -= cost;
    emit bankerChipsChanged();
    p->setChips(cost);
    emit playerRejoinedGame(seatIndex);
}

void GameEngine::placeBet(int rank, int amount, bool contre)
{
    if (m_gameState == GameOver || m_players.isEmpty()) return;
    if (amount <= 0 || amount > m_players[0]->chips()) return;
    if (rank < Card::Ace || rank > Card::King) return;
    if (m_caseKeeperData.contains(rank) && m_caseKeeperData[rank].size() >= 4) return;

    QVariantMap bets = m_players[0]->currentBets();
    QVariantMap bet;
    bet["amount"] = amount;
    bet["contre"] = contre;
    bets[QString::number(rank)] = bet;
    m_players[0]->setCurrentBets(bets);
    // currentBetsChanged + updateAllPlayerBets emitted via connection

    emit betPlaced(0, rank, amount, contre);
}

void GameEngine::removeBet(int rank)
{
    if (m_gameState == GameOver || m_players.isEmpty()) return;
    QVariantMap bets = m_players[0]->currentBets();
    bets.remove(QString::number(rank));
    m_players[0]->setCurrentBets(bets);
}

void GameEngine::placeHighCardBet(int amount, bool contre)
{
    if (m_gameState == GameOver || m_players.isEmpty()) return;
    if (amount <= 0 || amount > m_players[0]->chips()) return;
    QVariantMap bets = m_players[0]->currentBets();
    QVariantMap bet;
    bet["amount"] = amount;
    bet["contre"] = contre;
    bets["cartehaute"] = bet;
    m_players[0]->setCurrentBets(bets);
    emit betPlaced(0, -1, amount, contre);
}

// ── confirmBets / dealTurn ────────────────────────────────────────────────────

void GameEngine::confirmBets()
{
    if (!m_bettingPhase) return;
    stopBettingTimer();

    // Stop any still-thinking AI
    for (AIPlayer* ai : m_aiPlayers)
        ai->cancelBetting();

    m_bettingPhase = false;
    emit bettingPhaseChanged();

    setGameState(Dealing);
}

void GameEngine::dealTurn()
{
    if (m_deck.size() < 2) return;

    if (m_loserCard)  { m_discardPile.append(m_loserCard);  m_loserCard  = nullptr; }
    if (m_winnerCard) { m_discardPile.append(m_winnerCard); m_winnerCard = nullptr; }

    m_turnNumber++;
    emit turnNumberChanged();

    m_loserCard = m_deck.takeFirst();
    m_loserCard->setFaceUp(true);
    emit loserCardChanged();
    emit cardDealt(m_loserCard->rank(), m_loserCard->suit(), false);

    m_winnerCard = m_deck.takeFirst();
    m_winnerCard->setFaceUp(true);
    emit winnerCardChanged();
    emit cardDealt(m_winnerCard->rank(), m_winnerCard->suit(), true);

    QVariantMap li; li["suit"] = m_loserCard->suit(); li["type"] = "loser";
    m_caseKeeperData[m_loserCard->rank()].append(li);
    QVariantMap wi; wi["suit"] = m_winnerCard->suit(); wi["type"] = "winner";
    m_caseKeeperData[m_winnerCard->rank()].append(wi);

    emit cardsRemainingChanged();
    emit isLastThreeChanged();

    if (m_loserCard->rank() == m_winnerCard->rank())
        emit doubletOccurred(m_loserCard->rank());

    // Lock betting during card + chip animation (1s + 1s)
    m_bettingLocked = true;
    emit bettingLockedChanged();

    // After 1s card animation: settle bets (fires betWon/betLost chip animations)
    QTimer::singleShot(1000, this, [this]() {
        settleBets();

        // After 1s chip animation: unlock betting and start next round immediately
        QTimer::singleShot(1000, this, [this]() {
            m_bettingLocked = false;
            emit bettingLockedChanged();
            if (m_gameState != GameOver)
                nextBettingRound();
        });
    });
}

// ── settleBets ────────────────────────────────────────────────────────────────

void GameEngine::settleBets()
{
    bool isSplit = (m_loserCard->rank() == m_winnerCard->rank());
    QStringList results;
    int totalBankPayout = 0;
    int totalBankGain   = 0;

    for (PlayerModel* player : m_players) {
        int seat = player->seatIndex();
        QVariantMap playerBets = player->currentBets();
        int playerWinnings = 0;
        int playerLosses   = 0;

        for (auto it = playerBets.constBegin(); it != playerBets.constEnd(); ++it) {
            QString key    = it.key();
            QVariantMap bet = it.value().toMap();
            int  amount = bet["amount"].toInt();
            bool contre = bet["contre"].toBool();

            if (key == "cartehaute") {
                bool winnerHigher = m_winnerCard->rank() > m_loserCard->rank();
                bool betWins = contre ? !winnerHigher : winnerHigher;
                if (isSplit) {
                    int loss = amount / 2;
                    playerLosses += loss;
                    if (seat == 0) results.append(QString("Carte haute : doublet, perdu %1").arg(loss));
                    emit betLost(seat, -1, loss);
                } else if (betWins) {
                    playerWinnings += amount;
                    if (seat == 0) results.append(QString("Carte haute : gagné %1 !").arg(amount));
                    emit betWon(seat, -1, amount);
                } else {
                    playerLosses += amount;
                    if (seat == 0) results.append(QString("Carte haute : perdu %1").arg(amount));
                    emit betLost(seat, -1, amount);
                }
                continue;
            }

            int rank = key.toInt();

            if (isSplit && rank == m_loserCard->rank()) {
                int loss = amount / 2;
                playerLosses += loss;
                if (seat == 0)
                    results.append(QString("%1 : doublet ! Perdu %2").arg(rankToString(rank)).arg(loss));
                emit betLost(seat, rank, loss);
                continue;
            }

            bool isWinner = (rank == m_winnerCard->rank());
            bool isLoser  = (rank == m_loserCard->rank());

            if (isWinner) {
                if (contre) {
                    playerLosses += amount;
                    if (seat == 0)
                        results.append(QString("%1 : à contre, perdu %2").arg(rankToString(rank)).arg(amount));
                    emit betLost(seat, rank, amount);
                } else {
                    playerWinnings += amount;
                    if (seat == 0)
                        results.append(QString("%1 : gagné %2 !").arg(rankToString(rank)).arg(amount));
                    emit betWon(seat, rank, amount);
                }
            } else if (isLoser) {
                if (contre) {
                    playerWinnings += amount;
                    if (seat == 0)
                        results.append(QString("%1 : à contre, gagné %2 !").arg(rankToString(rank)).arg(amount));
                    emit betWon(seat, rank, amount);
                } else {
                    playerLosses += amount;
                    if (seat == 0)
                        results.append(QString("%1 : perdu %2").arg(rankToString(rank)).arg(amount));
                    emit betLost(seat, rank, amount);
                }
            }
            // bets on other ranks carry over — no chip change
        }

        int net = playerWinnings - playerLosses;
        player->setChips(player->chips() + net);

        if (net > 0) {
            totalBankPayout += net;
            emit playerWon(seat, net);
        } else if (net < 0) {
            totalBankGain += (-net);
            emit playerLost(seat, -net);
        }

        if (seat == 0) m_lastWinAmount = net;
    }

    m_bankerChips = m_bankerChips - totalBankPayout + totalBankGain;

    if (results.isEmpty())
        m_turnResultText = "Aucune mise impliquée cette donne.";
    else
        m_turnResultText = results.join("\n");

    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();

    // Bank broken check
    if (m_bankerChips <= 0) {
        m_bankerChips    = 0;
        m_bankBrokenState = true;

        int winnerSeat = 0, maxChips = 0;
        for (PlayerModel* p : m_players) {
            if (p->chips() > maxChips) {
                maxChips   = p->chips();
                winnerSeat = p->seatIndex();
            }
        }

        m_turnResultText += "\n\nLA BANQUE EST BRISÉE !";
        emit turnResultTextChanged();
        emit bankBrokenStateChanged();
        emit bankerChipsChanged();
        emit bankBroken(winnerSeat);
        setGameState(GameOver);
    }
}

// ── nextBettingRound ──────────────────────────────────────────────────────────

void GameEngine::nextBettingRound()
{
    // Carry over unmatched bets for all players
    for (PlayerModel* player : m_players) {
        QVariantMap carried;
        QVariantMap bets = player->currentBets();
        for (auto it = bets.constBegin(); it != bets.constEnd(); ++it) {
            QString key = it.key();
            if (key == "cartehaute") continue;
            int rank = key.toInt();
            bool matched = (m_loserCard  && rank == m_loserCard->rank()) ||
                           (m_winnerCard && rank == m_winnerCard->rank());
            if (!matched) carried[key] = it.value();
        }
        player->setCurrentBets(carried);
    }
    updateAllPlayerBets();
    emit currentBetsChanged();

    if (!m_players.isEmpty() && m_players[0]->chips() <= 0) {
        setGameState(GameOver);
        return;
    }
    if (m_deck.size() < 2) {
        setGameState(GameOver);
        return;
    }

    m_bettingPhase = true;
    emit bettingPhaseChanged();

    setGameState(Betting);
    startBettingTimer();
    startAIBetting();
}

// ── placeLastThreeBet ─────────────────────────────────────────────────────────

void GameEngine::placeLastThreeBet(int first, int second, int third, int amount)
{
    if (m_players.isEmpty()) return;
    if (amount <= 0 || amount > m_players[0]->chips()) return;

    m_lastThreeBet[0]    = first;
    m_lastThreeBet[1]    = second;
    m_lastThreeBet[2]    = third;
    m_lastThreeBetAmount = amount;

    m_turnNumber++;
    emit turnNumberChanged();

    if (m_loserCard)  { m_discardPile.append(m_loserCard);  m_loserCard  = nullptr; }
    if (m_winnerCard) { m_discardPile.append(m_winnerCard); m_winnerCard = nullptr; }

    m_loserCard  = m_deck.takeFirst(); m_loserCard->setFaceUp(true);
    m_winnerCard = m_deck.takeFirst(); m_winnerCard->setFaceUp(true);

    emit loserCardChanged();
    emit winnerCardChanged();

    QVariantMap li; li["suit"] = m_loserCard->suit(); li["type"] = "loser";
    m_caseKeeperData[m_loserCard->rank()].append(li);
    QVariantMap wi; wi["suit"] = m_winnerCard->suit(); wi["type"] = "winner";
    m_caseKeeperData[m_winnerCard->rank()].append(wi);

    settleBets();

    // Dernière carte (l'écart)
    Card* ecart = m_deck.takeFirst();
    ecart->setFaceUp(true);
    QVariantMap hi; hi["suit"] = ecart->suit(); hi["type"] = "ecart";
    m_caseKeeperData[ecart->rank()].append(hi);

    bool correct = (m_loserCard->rank()  == first  &&
                    m_winnerCard->rank() == second &&
                    ecart->rank()        == third);

    if (correct) {
        bool hasPair = (m_loserCard->rank() == m_winnerCard->rank()) ||
                       (m_loserCard->rank() == ecart->rank())        ||
                       (m_winnerCard->rank() == ecart->rank());
        int payout = hasPair ? amount * 2 : amount * 4;
        m_players[0]->setChips(m_players[0]->chips() + payout);
        m_bankerChips -= payout;
        m_turnResultText += QString("\nPrédiction finale : correcte ! Gagné %1 !").arg(payout);
        m_lastWinAmount  += payout;
    } else {
        m_players[0]->setChips(m_players[0]->chips() - amount);
        m_bankerChips += amount;
        m_turnResultText += QString("\nPrédiction finale : incorrecte. Perdu %1.").arg(amount);
    }

    m_discardPile.append(ecart);
    emit cardsRemainingChanged();
    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();

    setGameState(GameOver);
}

// ── startNewRound (bank broken → refill) ─────────────────────────────────────

void GameEngine::startNewRound()
{
    stopBettingTimer();

    qDeleteAll(m_deck);       m_deck.clear();
    qDeleteAll(m_discardPile); m_discardPile.clear();
    delete m_sodaCard;   m_sodaCard   = nullptr;
    delete m_loserCard;  m_loserCard  = nullptr;
    delete m_winnerCard; m_winnerCard = nullptr;

    m_caseKeeperData.clear();
    m_turnNumber         = 0;
    m_turnResultText.clear();
    m_lastWinAmount      = 0;
    m_lastThreeBetAmount = 0;
    m_bankBrokenState    = false;
    m_bankerChips        = m_initialBankChips;  // bank refills

    // Players KEEP their chips
    for (PlayerModel* p : m_players)
        p->setCurrentBets(QVariantMap());

    updateAllPlayerBets();

    buildDeck();
    shuffleDeck();

    m_sodaCard = m_deck.takeFirst();
    m_sodaCard->setFaceUp(true);
    QVariantMap si; si["suit"] = m_sodaCard->suit(); si["type"] = "souche";
    m_caseKeeperData[m_sodaCard->rank()].append(si);

    emit sodaCardChanged();
    emit cardsRemainingChanged();
    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnNumberChanged();
    emit currentBetsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();
    emit bankBrokenStateChanged();

    m_bettingPhase = true;
    emit bettingPhaseChanged();
    setGameState(Betting);

    startBettingTimer();
    startAIBetting();
    emit newRoundStarted();
}

// ── submitLeaderboardEntry ────────────────────────────────────────────────────

void GameEngine::submitLeaderboardEntry(const QString& initials)
{
    if (initials.isEmpty()) return;

    QVariantMap entry;
    entry["initials"]  = initials.toUpper().left(3);
    entry["chips"]     = m_players.isEmpty() ? 0 : m_players[0]->chips();
    entry["turn"]      = m_turnNumber;
    entry["timestamp"] = QDateTime::currentSecsSinceEpoch();

    m_leaderboard.prepend(entry);

    // Keep top 10 sorted by chips descending
    std::sort(m_leaderboard.begin(), m_leaderboard.end(),
        [](const QVariant& a, const QVariant& b) {
            return a.toMap()["chips"].toInt() > b.toMap()["chips"].toInt();
        });
    while (m_leaderboard.size() > 10)
        m_leaderboard.removeLast();

    QSettings s("QtShowcase", "Pharaon");
    s.setValue("Pharaon/leaderboard", m_leaderboard);

    emit leaderboardChanged();
}

// ── Case keeper queries ───────────────────────────────────────────────────────

int GameEngine::cardsShownForRank(int rank) const
{
    return m_caseKeeperData.value(rank).size();
}

QVariantList GameEngine::getShownCardsForRank(int rank) const
{
    return m_caseKeeperData.value(rank);
}

QVariantList GameEngine::aiBetsForRank(int rank) const
{
    QVariantList result;
    for (const auto &entry : m_allPlayerBets) {
        const QVariantMap m = entry.toMap();
        if (m["rank"].toInt() == rank && m["seatIndex"].toInt() > 0)
            result.append(entry);
    }
    return result;
}

QVariantList GameEngine::getRemainingThree() const
{
    QVariantList result;
    for (const Card* c : m_deck) {
        QVariantMap info;
        info["rank"] = c->rank();
        info["suit"] = c->suit();
        result.append(info);
    }
    return result;
}

// ── updateAllPlayerBets ───────────────────────────────────────────────────────

void GameEngine::updateAllPlayerBets()
{
    m_allPlayerBets.clear();
    for (PlayerModel* player : m_players) {
        const QString color = player->colorHex();
        int seat = player->seatIndex();
        QVariantMap bets = player->currentBets();
        for (auto it = bets.constBegin(); it != bets.constEnd(); ++it) {
            if (it.key() == "cartehaute") continue;
            QVariantMap bet = it.value().toMap();
            QVariantMap entry;
            entry["seatIndex"] = seat;
            entry["rank"]      = it.key().toInt();
            entry["amount"]    = bet["amount"];
            entry["contre"]    = bet["contre"];
            entry["colorHex"]  = color;
            m_allPlayerBets.append(entry);
        }
    }
    emit allPlayerBetsChanged();
}

// ── clearAllBets ──────────────────────────────────────────────────────────────

void GameEngine::clearAllBets()
{
    for (PlayerModel* p : m_players)
        p->setCurrentBets(QVariantMap());
    updateAllPlayerBets();
    emit currentBetsChanged();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

QString GameEngine::rankToString(int rank) const
{
    static const QStringList names = {
        "", "As", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "Valet", "Dame", "Roi"
    };
    return names.value(rank, "?");
}

QString GameEngine::suitSymbol(int suit) const
{
    static const QStringList symbols = { "♠", "♥", "♦", "♣" };
    return symbols.value(suit, "?");
}
