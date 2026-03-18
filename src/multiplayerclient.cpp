#include "multiplayerclient.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>
#include <QDebug>

MultiplayerClient::MultiplayerClient(QObject *parent)
    : QObject(parent)
    , m_socket(new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this))
    , m_playerId(QUuid::createUuid().toString(QUuid::WithoutBraces))
{
    connect(m_socket, &QWebSocket::connected,    this, &MultiplayerClient::onConnected);
    connect(m_socket, &QWebSocket::disconnected, this, &MultiplayerClient::onDisconnected);
    connect(m_socket, &QWebSocket::textMessageReceived,
            this, &MultiplayerClient::onTextMessageReceived);
    connect(m_socket, &QWebSocket::errorOccurred, this, &MultiplayerClient::onError);
}

MultiplayerClient::~MultiplayerClient()
{
    m_socket->close();
}

void MultiplayerClient::connectToServer(const QString& url, const QString& name, int chips)
{
    if (m_state != Disconnected) return;
    m_playerName = name;
    m_state = Connecting;
    emit connectionStateChanged();
    m_socket->open(QUrl(url));
    Q_UNUSED(chips)
}

void MultiplayerClient::disconnect()
{
    m_socket->close();
}

void MultiplayerClient::sendBet(int rank, int amount, bool contre)
{
    sendJson({{"type", "place_bet"},
              {"playerId", m_playerId},
              {"rank", rank},
              {"amount", amount},
              {"contre", contre}});
}

void MultiplayerClient::removeBet(int rank)
{
    sendJson({{"type", "remove_bet"},
              {"playerId", m_playerId},
              {"rank", rank}});
}

void MultiplayerClient::sendInitials(const QString& initials)
{
    sendJson({{"type", "submit_initials"},
              {"playerId", m_playerId},
              {"initials", initials}});
}

void MultiplayerClient::onConnected()
{
    m_state = Connected;
    emit connectionStateChanged();
    sendJson({{"type", "join"},
              {"playerId", m_playerId},
              {"playerName", m_playerName}});
}

void MultiplayerClient::onDisconnected()
{
    m_state = Disconnected;
    emit connectionStateChanged();
}

void MultiplayerClient::onTextMessageReceived(const QString& message)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError) return;
    emit serverMessage(doc.object().toVariantMap());
}

void MultiplayerClient::onError(QAbstractSocket::SocketError error)
{
    Q_UNUSED(error)
    emit errorOccurred(m_socket->errorString());
    m_state = Disconnected;
    emit connectionStateChanged();
}

void MultiplayerClient::sendJson(const QVariantMap& msg)
{
    if (m_state != Connected) return;
    QJsonDocument doc(QJsonObject::fromVariantMap(msg));
    m_socket->sendTextMessage(doc.toJson(QJsonDocument::Compact));
}
