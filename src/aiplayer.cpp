#include "aiplayer.h"
#include "playermodel.h"
#include <QTimer>
#include <QRandomGenerator>
#include <algorithm>

AIPlayer::AIPlayer(PlayerModel* player, int minStagger, int maxStagger, QObject* parent)
    : QObject(parent)
    , m_player(player)
    , m_minStagger(minStagger)
    , m_maxStagger(maxStagger)
{
    m_timer = new QTimer(this);
    m_timer->setSingleShot(true);
    connect(m_timer, &QTimer::timeout, this, &AIPlayer::decideBets);
}

void AIPlayer::startBettingPhase(const QMap<int, QVariantList>& tableau,
                                 int cardsLeft, int maxMs)
{
    m_tableau   = tableau;
    m_cardsLeft = cardsLeft;

    int clampedMax = maxMs - 400;
    int hi = qMin(m_maxStagger, clampedMax);
    int lo = qMin(m_minStagger, hi);
    int delay = (hi > lo)
        ? lo + static_cast<int>(QRandomGenerator::global()->bounded(static_cast<quint32>(hi - lo)))
        : lo;
    delay = qMax(delay, 0);

    m_player->setIsThinking(true);
    m_timer->start(delay);
}

void AIPlayer::cancelBetting()
{
    m_timer->stop();
    m_player->setIsThinking(false);
}

void AIPlayer::decideBets()
{
    m_player->setIsThinking(false);

    int stack = m_player->chips();
    if (stack <= 0) return;

    auto* rng = QRandomGenerator::global();

    // Gather eligible ranks (< 3 cards shown, some cards still in deck)
    QList<int> eligible;
    for (int rank = 1; rank <= 13; ++rank) {
        int shown = m_tableau.value(rank).size();
        if (shown < 3) {
            eligible.append(rank);
        }
    }

    if (eligible.isEmpty()) return;

    // Pick 1–3 ranks
    int count = 1 + static_cast<int>(rng->bounded(3u));
    count = qMin(count, eligible.size());

    // Shuffle eligible list
    for (int i = eligible.size() - 1; i > 0; --i) {
        int j = static_cast<int>(rng->bounded(static_cast<quint32>(i + 1)));
        eligible.swapItemsAt(i, j);
    }

    static const int amounts[] = {1, 5, 10, 25};
    QVariantMap bets;

    for (int i = 0; i < count; ++i) {
        int rank = eligible[i];

        // 5–15% of stack
        double pct = 0.05 + rng->generateDouble() * 0.10;
        int raw = static_cast<int>(stack * pct);
        // Round to nearest available chip denomination
        int amount = amounts[0];
        for (int a : amounts) {
            if (a <= raw) amount = a;
        }
        if (amount <= 0) amount = 1;
        if (amount > stack) amount = 1;

        bool contre = (rng->bounded(10u) < 2);  // 20% contre

        QVariantMap bet;
        bet["amount"] = amount;
        bet["contre"] = contre;
        bets[QString::number(rank)] = bet;
    }

    // 10% chance of carte haute bet
    if (rng->bounded(10u) == 0 && stack >= 1) {
        int raw = static_cast<int>(stack * (0.05 + rng->generateDouble() * 0.10));
        int amount = amounts[0];
        for (int a : amounts) {
            if (a <= raw) amount = a;
        }
        if (amount < 1) amount = 1;
        if (amount <= stack) {
            QVariantMap chBet;
            chBet["amount"] = amount;
            chBet["contre"] = (rng->bounded(5u) == 0);
            bets["cartehaute"] = chBet;
        }
    }

    emit betsReady(m_player->seatIndex(), bets);
}
