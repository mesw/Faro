#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QFont>
#include <QFontDatabase>
#include <QQmlEngine>

using namespace Qt::StringLiterals;

#include "gameengine.h"
#include "cardmodel.h"
#include "playermodel.h"
#include "casekeeper.h"
#include "appsettings.h"
#include "multiplayerclient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Faro");
    app.setOrganizationName("QtShowcase");
    app.setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Basic");

    // Initialise singleton so QML can access it
    AppSettings::instance();

    // Register QML types
    qmlRegisterType<GameEngine>      ("Faro.Engine", 1, 0, "GameEngine");
    qmlRegisterType<CardModel>       ("Faro.Engine", 1, 0, "CardModel");
    qmlRegisterType<PlayerModel>     ("Faro.Engine", 1, 0, "PlayerModel");
    qmlRegisterType<CaseKeeper>      ("Faro.Engine", 1, 0, "CaseKeeperModel");
    qmlRegisterType<MultiplayerClient>("Faro.Engine", 1, 0, "MultiplayerClient");

    qmlRegisterUncreatableType<Card> ("Faro.Engine", 1, 0, "CardInfo",
        "Card objects are created by the engine");

    // AppSettings singleton — accessible from QML as AppSettings { }
    qmlRegisterSingletonType<AppSettings>("Faro.Engine", 1, 0, "AppSettings",
        [](QQmlEngine*, QJSEngine*) -> QObject* {
            auto* s = AppSettings::instance();
            QQmlEngine::setObjectOwnership(s, QQmlEngine::CppOwnership);
            return s;
        });

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
