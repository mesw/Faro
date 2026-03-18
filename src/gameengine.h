#ifndef GAMEENGINE_H
#define GAMEENGINE_H

#include <QObject>
#include <QList>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlListProperty>
#include <QRandomGenerator>
#include <QTimer>

class PlayerModel;
class AIPlayer;

// ---------------------------------------------------------------------------
// Card — value type for a single playing card
// ---------------------------------------------------------------------------
class Card : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int  rank        READ rank        CONSTANT)
    Q_PROPERTY(int  suit        READ suit        CONSTANT)
    Q_PROPERTY(QString rankName READ rankName    CONSTANT)
    Q_PROPERTY(QString suitName READ suitName    CONSTANT)
    Q_PROPERTY(QString displayName READ displayName CONSTANT)
    Q_PROPERTY(QString shortName   READ shortName   CONSTANT)
    Q_PROPERTY(bool faceUp      READ faceUp      WRITE setFaceUp NOTIFY faceUpChanged)

public:
    enum Rank { Ace = 1, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten,
                Jack, Queen, King };
    Q_ENUM(Rank)

    enum Suit { Spades, Hearts, Diamonds, Clubs };
    Q_ENUM(Suit)

    explicit Card(int rank, int suit, QObject *parent = nullptr)
        : QObject(parent), m_rank(rank), m_suit(suit), m_faceUp(false) {}

    int  rank()   const { return m_rank; }
    int  suit()   const { return m_suit; }
    bool faceUp() const { return m_faceUp; }
    void setFaceUp(bool v) { if (m_faceUp != v) { m_faceUp = v; emit faceUpChanged(); } }

    QString rankName() const {
        static const QStringList names = {
            "", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"
        };
        return names.value(m_rank);
    }
    QString suitName() const {
        static const QStringList names = { "spades", "hearts", "diamonds", "clubs" };
        return names.value(m_suit);
    }
    QString displayName() const { return rankName() + " of " + suitName(); }
    QString shortName()   const {
        static const QStringList s = { "♠", "♥", "♦", "♣" };
        return rankName() + s.value(m_suit);
    }

signals:
    void faceUpChanged();

private:
    int  m_rank;
    int  m_suit;
    bool m_faceUp;
};


// ---------------------------------------------------------------------------
// GameEngine — central state machine
// ---------------------------------------------------------------------------
class GameEngine : public QObject
{
    Q_OBJECT

    // ── Backward-compatible single-player properties (delegate to seat 0) ──
    Q_PROPERTY(int gameState        READ gameState        WRITE setGameState   NOTIFY gameStateChanged)
    Q_PROPERTY(int turnNumber       READ turnNumber       NOTIFY turnNumberChanged)
    Q_PROPERTY(int cardsRemaining   READ cardsRemaining   NOTIFY cardsRemainingChanged)
    Q_PROPERTY(int playerChips      READ playerChips      NOTIFY playerChipsChanged)
    Q_PROPERTY(int bankerChips      READ bankerChips      NOTIFY bankerChipsChanged)

    Q_PROPERTY(Card* sodaCard       READ sodaCard         NOTIFY sodaCardChanged)
    Q_PROPERTY(Card* loserCard      READ loserCard        NOTIFY loserCardChanged)
    Q_PROPERTY(Card* winnerCard     READ winnerCard       NOTIFY winnerCardChanged)

    Q_PROPERTY(QVariantMap currentBets  READ currentBets  NOTIFY currentBetsChanged)
    Q_PROPERTY(bool bettingPhase        READ bettingPhase NOTIFY bettingPhaseChanged)
    Q_PROPERTY(bool isLastThree         READ isLastThree  NOTIFY isLastThreeChanged)

    Q_PROPERTY(QString turnResultText   READ turnResultText NOTIFY turnResultTextChanged)
    Q_PROPERTY(int     lastWinAmount    READ lastWinAmount  NOTIFY lastWinAmountChanged)

    // ── Multi-player / new properties ──
    Q_PROPERTY(QVariantList allPlayerBets         READ allPlayerBets         NOTIFY allPlayerBetsChanged)
    Q_PROPERTY(int          bettingTimerRemaining READ bettingTimerRemaining NOTIFY bettingTimerRemainingChanged)
    Q_PROPERTY(int          bettingTimeMs         READ bettingTimeMs         NOTIFY bettingTimeMsChanged)
    Q_PROPERTY(QVariantList players               READ playersVariant        NOTIFY playersChanged)
    Q_PROPERTY(bool         bankBrokenState       READ bankBrokenState       NOTIFY bankBrokenStateChanged)
    Q_PROPERTY(QVariantList leaderboard           READ leaderboard           NOTIFY leaderboardChanged)
    Q_PROPERTY(int          initialBankChips      READ initialBankChips      NOTIFY initialBankChipsChanged)

public:
    explicit GameEngine(QObject *parent = nullptr);
    ~GameEngine();

    enum GameState {
        Title = 0,
        Betting,
        Dealing,
        TurnResult,
        LastThreeBetting,
        GameOver
    };
    Q_ENUM(GameState)

    // ── Accessors ──
    int  gameState()      const { return m_gameState; }
    void setGameState(int state);
    int  turnNumber()     const { return m_turnNumber; }
    int  cardsRemaining() const { return m_deck.size(); }
    int  playerChips()    const;   // → m_players[0]->chips()
    int  bankerChips()    const { return m_bankerChips; }

    Card* sodaCard()   const { return m_sodaCard; }
    Card* loserCard()  const { return m_loserCard; }
    Card* winnerCard() const { return m_winnerCard; }

    QVariantMap currentBets() const;   // → m_players[0]->currentBets()
    bool  bettingPhase() const { return m_bettingPhase; }
    bool  isLastThree()  const { return m_deck.size() == 3; }

    QString turnResultText() const { return m_turnResultText; }
    int     lastWinAmount()  const { return m_lastWinAmount; }

    QVariantList allPlayerBets()         const { return m_allPlayerBets; }
    int          bettingTimerRemaining() const { return m_bettingTimerRemaining; }
    int          bettingTimeMs()         const { return m_bettingTimeMs; }
    QVariantList playersVariant()        const;
    bool         bankBrokenState()       const { return m_bankBrokenState; }
    QVariantList leaderboard()           const { return m_leaderboard; }
    int          initialBankChips()      const { return m_initialBankChips; }

    // ── Invokable methods (backward-compatible) ──
    Q_INVOKABLE void startNewGame(int startingChips = 100, int aiCount = -1);
    Q_INVOKABLE void placeBet(int rank, int amount, bool contre = false);
    Q_INVOKABLE void removeBet(int rank);
    Q_INVOKABLE void placeHighCardBet(int amount, bool contre = false);
    Q_INVOKABLE void confirmBets();
    Q_INVOKABLE void dealTurn();
    Q_INVOKABLE void nextBettingRound();
    Q_INVOKABLE void placeLastThreeBet(int first, int second, int third, int amount);

    // ── New methods ──
    Q_INVOKABLE void startNewRound();
    Q_INVOKABLE void submitLeaderboardEntry(const QString& initials);

    // ── Case keeper queries ──
    Q_INVOKABLE int          cardsShownForRank(int rank) const;
    Q_INVOKABLE QVariantList getShownCardsForRank(int rank) const;
    Q_INVOKABLE QVariantList getRemainingThree() const;

    // ── Card info helpers ──
    Q_INVOKABLE QString rankToString(int rank) const;
    Q_INVOKABLE QString suitSymbol(int suit) const;

signals:
    // Backward-compatible
    void gameStateChanged();
    void turnNumberChanged();
    void cardsRemainingChanged();
    void playerChipsChanged();
    void bankerChipsChanged();
    void sodaCardChanged();
    void loserCardChanged();
    void winnerCardChanged();
    void currentBetsChanged();
    void bettingPhaseChanged();
    void isLastThreeChanged();
    void turnResultTextChanged();
    void lastWinAmountChanged();

    // Animation triggers (extended with seatIndex)
    void cardDealt(int cardRank, int cardSuit, bool isWinner);
    void doubletOccurred(int rank);
    void playerWon(int seatIndex, int amount);
    void playerLost(int seatIndex, int amount);
    void chipsAnimated(int fromX, int fromY, int toX, int toY, int amount);

    // New signals
    void betWon(int seatIndex, int rank, int amount);
    void betLost(int seatIndex, int rank, int amount);
    void betPlaced(int seatIndex, int rank, int amount, bool contre);
    void aiBetPlaced(int seatIndex, int rank, int amount, bool contre);
    void bankBroken(int winnerSeat);
    void newRoundStarted();

    void allPlayerBetsChanged();
    void bettingTimerRemainingChanged();
    void bettingTimeMsChanged();
    void playersChanged();
    void bankBrokenStateChanged();
    void leaderboardChanged();
    void initialBankChipsChanged();

private slots:
    void onBettingTimerFired();
    void onBettingTickFired();
    void onAIBetsReady(int seatIndex, QVariantMap bets);

private:
    void buildDeck();
    void shuffleDeck();
    void settleBets();
    void updateAllPlayerBets();
    void startBettingTimer();
    void stopBettingTimer();
    void startAIBetting();
    void clearAllBets();

    int  m_gameState       = Title;
    int  m_turnNumber      = 0;
    int  m_bankerChips     = 1000;
    int  m_initialBankChips = 1000;
    bool m_bankBrokenState = false;

    QList<Card*> m_deck;
    QList<Card*> m_discardPile;

    Card* m_sodaCard   = nullptr;
    Card* m_loserCard  = nullptr;
    Card* m_winnerCard = nullptr;

    bool m_bettingPhase = false;

    // Multi-player
    QList<PlayerModel*> m_players;
    QList<AIPlayer*>    m_aiPlayers;
    QVariantList        m_allPlayerBets;

    // Betting timer
    QTimer* m_bettingTimer     = nullptr;
    QTimer* m_bettingTickTimer = nullptr;
    int     m_bettingTimerRemaining = 0;
    int     m_bettingTimeMs         = 20000;

    // Tableau
    QMap<int, QVariantList> m_caseKeeperData;

    QString m_turnResultText;
    int     m_lastWinAmount = 0;

    // Last three bet
    int m_lastThreeBet[3]    = {0, 0, 0};
    int m_lastThreeBetAmount = 0;

    // Leaderboard (offline)
    QVariantList m_leaderboard;
};

#endif // GAMEENGINE_H
