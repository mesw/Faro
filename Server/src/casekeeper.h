#ifndef CASEKEEPER_H
#define CASEKEEPER_H

#include <QObject>
#include <QVariantList>

class CaseKeeper : public QObject
{
    Q_OBJECT

public:
    explicit CaseKeeper(QObject *parent = nullptr);

    Q_INVOKABLE void reset();
    Q_INVOKABLE void recordCard(int rank, int suit, const QString &type);
    Q_INVOKABLE int shownCount(int rank) const;
    Q_INVOKABLE QVariantList shownCards(int rank) const;

signals:
    void dataChanged();

private:
    QMap<int, QVariantList> m_data;
};

#endif // CASEKEEPER_H
