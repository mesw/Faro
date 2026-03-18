#ifndef MULTIPLAYERCLIENT_H
#define MULTIPLAYERCLIENT_H

#include <QObject>
#include <QVariantMap>
#include <QtWebSockets/QWebSocket>

class MultiplayerClient : public QObject
{
    Q_OBJECT

public:
    enum ConnectionState { Disconnected, Connecting, Connected };
    Q_ENUM(ConnectionState)

    Q_PROPERTY(ConnectionState connectionState READ connectionState NOTIFY connectionStateChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)

    explicit MultiplayerClient(QObject *parent = nullptr);
    ~MultiplayerClient();

    ConnectionState connectionState() const { return m_state; }
    bool isConnected() const { return m_state == Connected; }

    Q_INVOKABLE void connectToServer(const QString& url,
                                     const QString& name,
                                     int chips);
    Q_INVOKABLE void disconnect();
    Q_INVOKABLE void sendBet(int rank, int amount, bool contre);
    Q_INVOKABLE void removeBet(int rank);
    Q_INVOKABLE void sendInitials(const QString& initials);

signals:
    void connectionStateChanged();
    void serverMessage(const QVariantMap& msg);
    void errorOccurred(const QString& msg);

private slots:
    void onConnected();
    void onDisconnected();
    void onTextMessageReceived(const QString& message);
    void onError(QAbstractSocket::SocketError error);

private:
    void sendJson(const QVariantMap& msg);

    QWebSocket*     m_socket;
    ConnectionState m_state = Disconnected;
    QString         m_playerId;
    QString         m_playerName;
};

#endif // MULTIPLAYERCLIENT_H
