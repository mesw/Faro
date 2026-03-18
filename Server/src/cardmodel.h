#ifndef CARDMODEL_H
#define CARDMODEL_H

#include <QAbstractListModel>
#include <QObject>

class CardModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        RankRole = Qt::UserRole + 1,
        RankNameRole,
        SuitSymbolRole,
        DisplayNameRole
    };

    explicit CardModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    struct CardInfo {
        int rank;
        QString rankName;
        QString suitSymbol;
    };
    QList<CardInfo> m_cards;
};

#endif // CARDMODEL_H
