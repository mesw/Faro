#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>

class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int     bettingTimerMs  READ bettingTimerMs  WRITE setBettingTimerMs  NOTIFY bettingTimerMsChanged)
    Q_PROPERTY(int     aiPlayerCount   READ aiPlayerCount   WRITE setAiPlayerCount   NOTIFY aiPlayerCountChanged)
    Q_PROPERTY(QString serverUrl       READ serverUrl       WRITE setServerUrl       NOTIFY serverUrlChanged)
    Q_PROPERTY(int     startingChips   READ startingChips   WRITE setStartingChips   NOTIFY startingChipsChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    static AppSettings* instance();

    int     bettingTimerMs() const { return m_bettingTimerMs; }
    int     aiPlayerCount()  const { return m_aiPlayerCount; }
    QString serverUrl()      const { return m_serverUrl; }
    int     startingChips()  const { return m_startingChips; }

    void setBettingTimerMs(int ms);
    void setAiPlayerCount(int count);
    void setServerUrl(const QString &url);
    void setStartingChips(int chips);

    Q_INVOKABLE void save();
    Q_INVOKABLE void load();
    Q_INVOKABLE void resetToDefaults();

signals:
    void bettingTimerMsChanged();
    void aiPlayerCountChanged();
    void serverUrlChanged();
    void startingChipsChanged();

private:
    static AppSettings* s_instance;

    int     m_bettingTimerMs = 20000;   // 20 s default
    int     m_aiPlayerCount  = 2;
    QString m_serverUrl;
    int     m_startingChips  = 100;
};

#endif // APPSETTINGS_H
