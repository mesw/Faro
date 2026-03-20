cmake_minimum_required(VERSION 3.16)

project(FaroGame VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    QuickControls2
    Multimedia
    WebSockets
    ShaderTools
)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(FaroGame
    src/main.cpp
    src/gameengine.cpp
    src/gameengine.h
    src/cardmodel.cpp
    src/cardmodel.h
    src/playermodel.cpp
    src/playermodel.h
    src/casekeeper.cpp
    src/casekeeper.h
    src/appsettings.cpp
    src/appsettings.h
    src/aiplayer.cpp
    src/aiplayer.h
    src/multiplayerclient.cpp
    src/multiplayerclient.h
)

qt_add_qml_module(FaroGame
    URI Faro
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/Card.qml
        qml/components/FaroTable.qml
        qml/components/ChipStack.qml
        qml/components/CaseKeeper.qml
        qml/components/DealerBox.qml
        qml/components/BettingChip.qml
        qml/components/CardFan.qml
        qml/components/ParticleOverlay.qml
        qml/components/GoldText.qml
        qml/components/PlayerPanel.qml
        qml/components/PlayerTray.qml
        qml/components/FlyingCard.qml
        qml/components/FlyingChip.qml
        qml/components/LeaderboardPanel.qml
        qml/components/InitialsEntry.qml
        qml/views/TitleScreen.qml
        qml/views/GameView.qml
        qml/views/ResultsView.qml
        qml/views/SettingsView.qml
    RESOURCES
        resources/felt_texture.png
        resources/wood_texture.png
        resources/chip_texture.png
        resources/gold_foil.png
)

# Shader compilation for visual effects
#qt6_add_shaders(FaroGame "shaders"
#    PREFIX "/"
#    FILES
#        resources/shaders/felt.frag
#        resources/shaders/glow.frag
#        resources/shaders/vignette.frag
#)

target_link_libraries(FaroGame PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::WebSockets
)

# Platform-specific settings
if(EMSCRIPTEN)
    target_link_options(FaroGame PRIVATE
        "SHELL:-s ASYNCIFY=1"
        "SHELL:-s TOTAL_MEMORY=256MB"
        "SHELL:-s ALLOW_MEMORY_GROWTH=1"
        "SHELL:-s EXPORTED_RUNTIME_METHODS=['UTF8ToString','stringToUTF8']"
    )
endif()

install(TARGETS FaroGame
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
