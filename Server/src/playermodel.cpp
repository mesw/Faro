#include "playermodel.h"

PlayerModel::PlayerModel(QObject *parent)
    : QObject(parent)
{
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
