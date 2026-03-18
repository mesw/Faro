#ifndef PLAYERMODEL_H
#define PLAYERMODEL_H

#include <QObject>

class PlayerModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int chips READ chips WRITE setChips NOTIFY chipsChanged)
    Q_PROPERTY(bool isActive READ isActive WRITE setIsActive NOTIFY isActiveChanged)

public:
    explicit PlayerModel(QObject *parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString &name);
    int chips() const { return m_chips; }
    void setChips(int chips);
    bool isActive() const { return m_isActive; }
    void setIsActive(bool active);

signals:
    void nameChanged();
    void chipsChanged();
    void isActiveChanged();

private:
    QString m_name = "Player";
    int m_chips = 100;
    bool m_isActive = true;
};

#endif // PLAYERMODEL_H
