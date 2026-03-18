#include "casekeeper.h"

CaseKeeper::CaseKeeper(QObject *parent)
    : QObject(parent)
{
}

void CaseKeeper::reset()
{
    m_data.clear();
    emit dataChanged();
}

void CaseKeeper::recordCard(int rank, int suit, const QString &type)
{
    QVariantMap info;
    info["suit"] = suit;
    info["type"] = type;
    m_data[rank].append(info);
    emit dataChanged();
}

int CaseKeeper::shownCount(int rank) const
{
    return m_data.value(rank).size();
}

QVariantList CaseKeeper::shownCards(int rank) const
{
    return m_data.value(rank);
}
