#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QFont>
#include <QFontDatabase>

using namespace Qt::StringLiterals;

#include "gameengine.h"
#include "cardmodel.h"
#include "playermodel.h"
#include "casekeeper.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Faro");
    app.setOrganizationName("QtShowcase");
    app.setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Basic");

    // Register QML types
    qmlRegisterType<GameEngine>("Faro.Engine", 1, 0, "GameEngine");
    qmlRegisterType<CardModel>("Faro.Engine", 1, 0, "CardModel");
    qmlRegisterType<PlayerModel>("Faro.Engine", 1, 0, "PlayerModel");
    qmlRegisterType<CaseKeeper>("Faro.Engine", 1, 0, "CaseKeeperModel");
    qmlRegisterUncreatableType<Card>("Faro.Engine", 1, 0, "CardInfo",
        "Card objects are created by the engine");

    QQmlApplicationEngine engine;

    const QUrl url(u"qrc:/qt/qml/Faro/qml/Main.qml"_s);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );
    engine.load(url);

    return app.exec();
}
