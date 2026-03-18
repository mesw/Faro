#include "playermodel.h"

static const char* kSeatColors[] = {
    "#c9a227",  // seat 0: gold (human)
    "#b0c4de",  // seat 1: silver-blue
    "#cd7f32",  // seat 2: bronze
    "#9370db",  // seat 3: purple
    "#48c774"   // seat 4: green
};

PlayerModel::PlayerModel(QObject *parent)
    : QObject(parent)
    , m_playerId(QUuid::createUuid().toString(QUuid::WithoutBraces))
{
}

PlayerModel* PlayerModel::createHuman(int chips, int seat, QObject* parent)
{
    auto* p = new PlayerModel(parent);
    p->m_name       = "Joueur";
    p->m_chips      = chips;
    p->m_playerType = Human;
    p->m_seatIndex  = seat;
    p->m_colorHex   = (seat >= 0 && seat < 5) ? kSeatColors[seat] : kSeatColors[0];
    return p;
}

PlayerModel* PlayerModel::createAI(const QString& name, int chips, int seat, QObject* parent)
{
    auto* p = new PlayerModel(parent);
    p->m_name       = name;
    p->m_chips      = chips;
    p->m_playerType = AI;
    p->m_seatIndex  = seat;
    p->m_colorHex   = (seat >= 0 && seat < 5) ? kSeatColors[seat] : kSeatColors[1];
    return p;
}

const char* PlayerModel::seatColor(int seat)
{
    return (seat >= 0 && seat < 5) ? kSeatColors[seat] : kSeatColors[0];
}

void PlayerModel::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void PlayerModel::setChips(int chips)
{
    if (m_chips != chips) {
        m_chips = chips;
        emit chipsChanged();
    }
}

void PlayerModel::setIsActive(bool active)
{
    if (m_isActive != active) {
        m_isActive = active;
        emit isActiveChanged();
    }
}

void PlayerModel::setCurrentBets(const QVariantMap &bets)
{
    if (m_currentBets != bets) {
        m_currentBets = bets;
        emit currentBetsChanged();
    }
}

void PlayerModel::setIsConnected(bool connected)
{
    if (m_isConnected != connected) {
        m_isConnected = connected;
        emit isConnectedChanged();
    }
}

void PlayerModel::setIsThinking(bool thinking)
{
    if (m_isThinking != thinking) {
        m_isThinking = thinking;
        emit isThinkingChanged();
    }
}
