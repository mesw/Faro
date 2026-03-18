#ifndef PLAYERMODEL_H
#define PLAYERMODEL_H

#include <QObject>
#include <QVariantMap>
#include <QUuid>

class PlayerModel : public QObject
{
    Q_OBJECT

public:
    enum PlayerType { Human, AI };
    Q_ENUM(PlayerType)

private:
    Q_PROPERTY(QString     name         READ name         WRITE setName         NOTIFY nameChanged)
    Q_PROPERTY(int         chips        READ chips        WRITE setChips        NOTIFY chipsChanged)
    Q_PROPERTY(bool        isActive     READ isActive     WRITE setIsActive     NOTIFY isActiveChanged)
    Q_PROPERTY(PlayerType  playerType   READ playerType   CONSTANT)
    Q_PROPERTY(QString     playerId     READ playerId     CONSTANT)
    Q_PROPERTY(int         seatIndex    READ seatIndex    CONSTANT)
    Q_PROPERTY(QVariantMap currentBets  READ currentBets  WRITE setCurrentBets  NOTIFY currentBetsChanged)
    Q_PROPERTY(bool        isConnected  READ isConnected  WRITE setIsConnected  NOTIFY isConnectedChanged)
    Q_PROPERTY(bool        isThinking   READ isThinking   WRITE setIsThinking   NOTIFY isThinkingChanged)
    Q_PROPERTY(QString     colorHex     READ colorHex     CONSTANT)

public:
    explicit PlayerModel(QObject *parent = nullptr);

    static PlayerModel* createHuman(int chips, int seat, QObject* parent = nullptr);
    static PlayerModel* createAI(const QString& name, int chips, int seat, QObject* parent = nullptr);

    QString     name()        const { return m_name; }
    int         chips()       const { return m_chips; }
    bool        isActive()    const { return m_isActive; }
    PlayerType  playerType()  const { return m_playerType; }
    QString     playerId()    const { return m_playerId; }
    int         seatIndex()   const { return m_seatIndex; }
    QVariantMap currentBets() const { return m_currentBets; }
    bool        isConnected() const { return m_isConnected; }
    bool        isThinking()  const { return m_isThinking; }
    QString     colorHex()    const { return m_colorHex; }

    void setName(const QString &name);
    void setChips(int chips);
    void setIsActive(bool active);
    void setCurrentBets(const QVariantMap &bets);
    void setIsConnected(bool connected);
    void setIsThinking(bool thinking);

    // Internal setters used during construction
    void initSeat(int seat)          { m_seatIndex  = seat; }
    void initType(PlayerType type)   { m_playerType = type; }
    void initColor(const QString &c) { m_colorHex   = c; }

signals:
    void nameChanged();
    void chipsChanged();
    void isActiveChanged();
    void currentBetsChanged();
    void isConnectedChanged();
    void isThinkingChanged();

private:
    QString     m_name        = "Player";
    int         m_chips       = 100;
    bool        m_isActive    = true;
    PlayerType  m_playerType  = Human;
    QString     m_playerId;
    int         m_seatIndex   = 0;
    QVariantMap m_currentBets;
    bool        m_isConnected = true;
    bool        m_isThinking  = false;
    QString     m_colorHex    = "#c9a227";

    static const char* seatColor(int seat);
};

#endif // PLAYERMODEL_H
