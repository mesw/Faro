#ifndef AIPLAYER_H
#define AIPLAYER_H

#include <QObject>
#include <QVariantMap>
#include <QMap>
#include <QVariantList>

class QTimer;
class PlayerModel;

class AIPlayer : public QObject
{
    Q_OBJECT

public:
    // minStagger / maxStagger in ms before the AI places its bets
    explicit AIPlayer(PlayerModel* player, int minStagger, int maxStagger,
                      QObject* parent = nullptr);

    // Call at the start of each betting round.
    // maxMs = total betting window; AI will clamp to maxMs-400
    void startBettingPhase(const QMap<int, QVariantList>& tableau,
                           int cardsLeft, int maxMs);

    void cancelBetting();

signals:
    // Emitted after stagger delay with chosen bets
    void betsReady(int seatIndex, QVariantMap bets);

private slots:
    void decideBets();

private:
    PlayerModel*            m_player;
    int                     m_minStagger;
    int                     m_maxStagger;
    QTimer*                 m_timer;
    QMap<int, QVariantList> m_tableau;
    int                     m_cardsLeft = 0;
};

#endif // AIPLAYER_H
