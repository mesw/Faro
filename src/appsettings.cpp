#include "appsettings.h"

AppSettings* AppSettings::s_instance = nullptr;

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
{
    load();
}

AppSettings* AppSettings::instance()
{
    if (!s_instance) {
        s_instance = new AppSettings();
    }
    return s_instance;
}

void AppSettings::setBettingTimerMs(int ms)
{
    ms = qBound(1000, ms, 30000);
    if (m_bettingTimerMs != ms) {
        m_bettingTimerMs = ms;
        emit bettingTimerMsChanged();
    }
}

void AppSettings::setAiPlayerCount(int count)
{
    count = qBound(0, count, 4);
    if (m_aiPlayerCount != count) {
        m_aiPlayerCount = count;
        emit aiPlayerCountChanged();
    }
}

void AppSettings::setServerUrl(const QString &url)
{
    if (m_serverUrl != url) {
        m_serverUrl = url;
        emit serverUrlChanged();
    }
}

void AppSettings::setStartingChips(int chips)
{
    if (m_startingChips != chips) {
        m_startingChips = chips;
        emit startingChipsChanged();
    }
}

void AppSettings::save()
{
    QSettings settings("QtShowcase", "Pharaon");
    settings.beginGroup("Pharaon");
    settings.setValue("bettingTimerMs", m_bettingTimerMs);
    settings.setValue("aiPlayerCount",  m_aiPlayerCount);
    settings.setValue("serverUrl",      m_serverUrl);
    settings.setValue("startingChips",  m_startingChips);
    settings.endGroup();
}

void AppSettings::load()
{
    QSettings settings("QtShowcase", "Pharaon");
    settings.beginGroup("Pharaon");
    setBettingTimerMs(settings.value("bettingTimerMs", 5000).toInt());
    setAiPlayerCount(settings.value("aiPlayerCount",  2).toInt());
    setServerUrl(settings.value("serverUrl", "").toString());
    setStartingChips(settings.value("startingChips", 100).toInt());
    settings.endGroup();
}

void AppSettings::resetToDefaults()
{
    setBettingTimerMs(5000);
    setAiPlayerCount(2);
    setServerUrl(QString());
    setStartingChips(100);
}
