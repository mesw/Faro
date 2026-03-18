#include "cardmodel.h"

CardModel::CardModel(QObject *parent)
    : QAbstractListModel(parent)
{
    static const QList<QPair<int,QString>> ranks = {
        {13,"K"}, {12,"Q"}, {11,"J"}, {10,"10"}, {9,"9"}, {8,"8"}, {7,"7"},
        {6,"6"}, {5,"5"}, {4,"4"}, {3,"3"}, {2,"2"}, {1,"A"}
    };
    for (const auto &r : ranks)
        m_cards.append({r.first, r.second, "♠"});
}

int CardModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_cards.size();
}

QVariant CardModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_cards.size())
        return {};
    const CardInfo &card = m_cards.at(index.row());
    switch (role) {
    case RankRole:       return card.rank;
    case RankNameRole:   return card.rankName;
    case SuitSymbolRole: return card.suitSymbol;
    case DisplayNameRole: return card.rankName + card.suitSymbol;
    }
    return {};
}

QHash<int, QByteArray> CardModel::roleNames() const
{
    return {
        {RankRole,       "rank"},
        {RankNameRole,   "rankName"},
        {SuitSymbolRole, "suitSymbol"},
        {DisplayNameRole,"displayName"}
    };
}
