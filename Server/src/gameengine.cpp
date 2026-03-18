#include "gameengine.h"
#include <QDebug>
#include <algorithm>

GameEngine::GameEngine(QObject *parent)
    : QObject(parent)
{
}

GameEngine::~GameEngine()
{
    qDeleteAll(m_deck);
    qDeleteAll(m_discardPile);
    delete m_sodaCard;
    delete m_loserCard;
    delete m_winnerCard;
}

void GameEngine::setGameState(int state)
{
    if (m_gameState != state) {
        m_gameState = state;
        emit gameStateChanged();
    }
}

void GameEngine::startNewGame(int startingChips)
{
    // Clean up previous game
    qDeleteAll(m_deck);
    m_deck.clear();
    qDeleteAll(m_discardPile);
    m_discardPile.clear();

    if (m_sodaCard) { delete m_sodaCard; m_sodaCard = nullptr; }
    if (m_loserCard) { delete m_loserCard; m_loserCard = nullptr; }
    if (m_winnerCard) { delete m_winnerCard; m_winnerCard = nullptr; }

    m_currentBets.clear();
    m_caseKeeperData.clear();
    m_turnNumber = 0;
    m_playerChips = startingChips;
    m_bankerChips = 1000;
    m_turnResultText.clear();
    m_lastWinAmount = 0;
    m_lastThreeBetAmount = 0;

    buildDeck();
    shuffleDeck();

    // Deal the souche (first card, shown before betting)
    m_sodaCard = m_deck.takeFirst();
    m_sodaCard->setFaceUp(true);

    // Record souche in tableau
    QVariantMap sodaInfo;
    sodaInfo["suit"] = m_sodaCard->suit();
    sodaInfo["type"] = "souche";
    m_caseKeeperData[m_sodaCard->rank()].append(sodaInfo);

    emit sodaCardChanged();
    emit cardsRemainingChanged();
    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnNumberChanged();
    emit currentBetsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();

    m_bettingPhase = true;
    emit bettingPhaseChanged();
    setGameState(Betting);
}

void GameEngine::buildDeck()
{
    for (int suit = Card::Spades; suit <= Card::Clubs; ++suit) {
        for (int rank = Card::Ace; rank <= Card::King; ++rank) {
            m_deck.append(new Card(rank, suit, this));
        }
    }
}

void GameEngine::shuffleDeck()
{
    auto *rng = QRandomGenerator::global();
    for (int i = m_deck.size() - 1; i > 0; --i) {
        int j = rng->bounded(i + 1);
        m_deck.swapItemsAt(i, j);
    }
}

void GameEngine::placeBet(int rank, int amount, bool contre)
{
    if (!m_bettingPhase || amount <= 0 || amount > m_playerChips)
        return;

    if (rank < Card::Ace || rank > Card::King)
        return;

    // Check if all 4 cards of this rank are already shown
    if (m_caseKeeperData.contains(rank) && m_caseKeeperData[rank].size() >= 4)
        return;

    QVariantMap bet;
    bet["amount"] = amount;
    bet["contre"] = contre;
    m_currentBets[QString::number(rank)] = bet;

    emit currentBetsChanged();
}

void GameEngine::removeBet(int rank)
{
    if (!m_bettingPhase)
        return;

    m_currentBets.remove(QString::number(rank));
    emit currentBetsChanged();
}

void GameEngine::placeHighCardBet(int amount, bool contre)
{
    if (!m_bettingPhase || amount <= 0 || amount > m_playerChips)
        return;

    QVariantMap bet;
    bet["amount"] = amount;
    bet["contre"] = contre;
    m_currentBets["cartehaute"] = bet;
    emit currentBetsChanged();
}

void GameEngine::confirmBets()
{
    if (!m_bettingPhase)
        return;

    m_bettingPhase = false;
    emit bettingPhaseChanged();

    if (m_deck.size() == 3) {
        setGameState(LastThreeBetting);
    } else {
        setGameState(Dealing);
    }
}

void GameEngine::dealTurn()
{
    if (m_deck.size() < 2)
        return;

    // Clean up previous turn cards (not soda)
    if (m_loserCard) {
        m_discardPile.append(m_loserCard);
        m_loserCard = nullptr;
    }
    if (m_winnerCard) {
        m_discardPile.append(m_winnerCard);
        m_winnerCard = nullptr;
    }

    m_turnNumber++;
    emit turnNumberChanged();

    // Deal loser card
    m_loserCard = m_deck.takeFirst();
    m_loserCard->setFaceUp(true);
    emit loserCardChanged();
    emit cardDealt(m_loserCard->rank(), m_loserCard->suit(), false);

    // Deal winner card (top of remaining deck, revealed face-up)
    m_winnerCard = m_deck.takeFirst();
    m_winnerCard->setFaceUp(true);
    emit winnerCardChanged();
    emit cardDealt(m_winnerCard->rank(), m_winnerCard->suit(), true);

    // Record in tableau
    QVariantMap loserInfo;
    loserInfo["suit"] = m_loserCard->suit();
    loserInfo["type"] = "loser";
    m_caseKeeperData[m_loserCard->rank()].append(loserInfo);

    QVariantMap winnerInfo;
    winnerInfo["suit"] = m_winnerCard->suit();
    winnerInfo["type"] = "winner";
    m_caseKeeperData[m_winnerCard->rank()].append(winnerInfo);

    emit cardsRemainingChanged();
    emit isLastThreeChanged();

    // Check for doublet
    if (m_loserCard->rank() == m_winnerCard->rank()) {
        emit doubletOccurred(m_loserCard->rank());
    }

    // Settle bets
    settleBets();

    setGameState(TurnResult);
}

void GameEngine::settleBets()
{
    int totalWinnings = 0;
    int totalLosses = 0;
    QStringList results;

    bool isSplit = (m_loserCard->rank() == m_winnerCard->rank());

    for (auto it = m_currentBets.constBegin(); it != m_currentBets.constEnd(); ++it) {
        QString key = it.key();
        QVariantMap bet = it.value().toMap();
        int amount = bet["amount"].toInt();
        bool contre = bet["contre"].toBool();

        if (key == "cartehaute") {
            // Carte haute : le rang du gagnant supérieur au perdant
            bool winnerHigher = m_winnerCard->rank() > m_loserCard->rank();
            bool betWins = contre ? !winnerHigher : winnerHigher;

            if (isSplit) {
                int loss = amount / 2;
                totalLosses += loss;
                results.append(QString("Carte haute : doublet, perdu %1").arg(loss));
            } else if (betWins) {
                totalWinnings += amount;
                results.append(QString("Carte haute : gagné %1 !").arg(amount));
            } else {
                totalLosses += amount;
                results.append(QString("Carte haute : perdu %1").arg(amount));
            }
            continue;
        }

        int rank = key.toInt();

        if (isSplit && rank == m_loserCard->rank()) {
            int loss = amount / 2;
            totalLosses += loss;
            results.append(QString("%1 : doublet ! Perdu %2")
                .arg(rankToString(rank)).arg(loss));
            continue;
        }

        bool isWinner = (rank == m_winnerCard->rank());
        bool isLoser = (rank == m_loserCard->rank());

        if (isWinner) {
            if (contre) {
                totalLosses += amount;
                results.append(QString("%1 : à contre, perdu %2")
                    .arg(rankToString(rank)).arg(amount));
            } else {
                totalWinnings += amount;
                results.append(QString("%1 : gagné %2 !")
                    .arg(rankToString(rank)).arg(amount));
            }
        } else if (isLoser) {
            if (contre) {
                totalWinnings += amount;
                results.append(QString("%1 : à contre, gagné %2 !")
                    .arg(rankToString(rank)).arg(amount));
            } else {
                totalLosses += amount;
                results.append(QString("%1 : perdu %2")
                    .arg(rankToString(rank)).arg(amount));
            }
        }
        // Cards that are neither winner nor loser: bet carries over (stays)
    }

    m_playerChips += totalWinnings - totalLosses;
    m_bankerChips -= totalWinnings - totalLosses;

    m_lastWinAmount = totalWinnings - totalLosses;

    if (results.isEmpty()) {
        m_turnResultText = "Aucune mise impliquée cette donne.";
    } else {
        m_turnResultText = results.join("\n");
    }

    if (totalWinnings > totalLosses) {
        emit playerWon(totalWinnings - totalLosses);
    } else if (totalLosses > totalWinnings) {
        emit playerLost(totalLosses - totalWinnings);
    }

    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();
}

void GameEngine::nextBettingRound()
{
    // Remove bets that matched (won or lost). Keep bets that didn't match.
    QVariantMap carriedBets;
    for (auto it = m_currentBets.constBegin(); it != m_currentBets.constEnd(); ++it) {
        QString key = it.key();
        if (key == "cartehaute") continue; // Carte haute ne se reporte pas

        int rank = key.toInt();
        bool matched = (m_loserCard && rank == m_loserCard->rank()) ||
                       (m_winnerCard && rank == m_winnerCard->rank());
        if (!matched) {
            carriedBets[key] = it.value();
        }
    }
    m_currentBets = carriedBets;
    emit currentBetsChanged();

    if (m_playerChips <= 0) {
        setGameState(GameOver);
        return;
    }

    if (m_deck.size() <= 1) {
        // Hock card (last card) - game ends
        setGameState(GameOver);
        return;
    }

    m_bettingPhase = true;
    emit bettingPhaseChanged();

    if (m_deck.size() == 3) {
        setGameState(LastThreeBetting);
    } else {
        setGameState(Betting);
    }
}

void GameEngine::placeLastThreeBet(int first, int second, int third, int amount)
{
    if (amount <= 0 || amount > m_playerChips)
        return;

    m_lastThreeBet[0] = first;
    m_lastThreeBet[1] = second;
    m_lastThreeBet[2] = third;
    m_lastThreeBetAmount = amount;

    // Deal the last three cards
    m_turnNumber++;
    emit turnNumberChanged();

    if (m_loserCard) { m_discardPile.append(m_loserCard); m_loserCard = nullptr; }
    if (m_winnerCard) { m_discardPile.append(m_winnerCard); m_winnerCard = nullptr; }

    // Normal turn with first two
    m_loserCard = m_deck.takeFirst();
    m_loserCard->setFaceUp(true);
    m_winnerCard = m_deck.takeFirst();
    m_winnerCard->setFaceUp(true);

    emit loserCardChanged();
    emit winnerCardChanged();

    QVariantMap li;
    li["suit"] = m_loserCard->suit();
    li["type"] = "loser";
    m_caseKeeperData[m_loserCard->rank()].append(li);

    QVariantMap wi;
    wi["suit"] = m_winnerCard->suit();
    wi["type"] = "winner";
    m_caseKeeperData[m_winnerCard->rank()].append(wi);

    // Settle normal bets
    settleBets();

    // Dernière carte (l'écart — last card, not playable)
    Card* ecart = m_deck.takeFirst();
    ecart->setFaceUp(true);
    QVariantMap hi;
    hi["suit"] = ecart->suit();
    hi["type"] = "ecart";
    m_caseKeeperData[ecart->rank()].append(hi);

    // Check last three prediction
    bool correct = (m_loserCard->rank() == first &&
                    m_winnerCard->rank() == second &&
                    ecart->rank() == third);

    if (correct) {
        // Check for pair among the three
        bool hasPair = (m_loserCard->rank() == m_winnerCard->rank()) ||
                       (m_loserCard->rank() == ecart->rank()) ||
                       (m_winnerCard->rank() == ecart->rank());
        int payout = hasPair ? m_lastThreeBetAmount * 2 : m_lastThreeBetAmount * 4;
        m_playerChips += payout;
        m_bankerChips -= payout;
        m_turnResultText += QString("\nPrédiction finale : correcte ! Gagné %1 !").arg(payout);
        m_lastWinAmount += payout;
    } else {
        m_playerChips -= m_lastThreeBetAmount;
        m_bankerChips += m_lastThreeBetAmount;
        m_turnResultText += QString("\nPrédiction finale : incorrecte. Perdu %1.").arg(m_lastThreeBetAmount);
    }

    m_discardPile.append(ecart);

    emit cardsRemainingChanged();
    emit playerChipsChanged();
    emit bankerChipsChanged();
    emit turnResultTextChanged();
    emit lastWinAmountChanged();

    setGameState(GameOver);
}

int GameEngine::cardsShownForRank(int rank) const
{
    return m_caseKeeperData.value(rank).size();
}

QVariantList GameEngine::getShownCardsForRank(int rank) const
{
    return m_caseKeeperData.value(rank);
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
