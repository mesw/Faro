// ─────────────────────────────────────────────────────────────────────────────
// Pharaon multiplayer server — Cloudflare Durable Object
// ─────────────────────────────────────────────────────────────────────────────

export interface Env {
  PHARAON_ROOM: DurableObjectNamespace;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Card       { rank: number; suit: number }
interface Bet        { amount: number; contre: boolean }
interface PlayerBets { [rankOrKey: string]: Bet }

interface PlayerState {
  name:      string;
  chips:     number;
  bets:      PlayerBets;
  connected: boolean;
}

interface GameState {
  phase:       "waiting" | "betting" | "dealing" | "turn_result" | "game_over";
  turnNumber:  number;
  bankChips:   number;
  deckCards:   Card[];
  cardsDealt:  { suit: number; type: string }[];   // per-rank history flattened (rank → suits)
  tableau:     { [rank: number]: { suit: number; type: string }[] };
  sodaCard:    Card | null;
  loserCard:   Card | null;
  winnerCard:  Card | null;
  bettingEndsAt: number;  // ms epoch
}

interface Settings {
  bettingTimerMs: number;
  startingChips:  number;
  bankChips:      number;
}

const DEFAULT_SETTINGS: Settings = {
  bettingTimerMs: 20000,
  startingChips:  100,
  bankChips:      1000,
};

// ---------------------------------------------------------------------------
// PharaonRoom — one Durable Object per room
// ---------------------------------------------------------------------------
export class PharaonRoom implements DurableObject {
  private players:  Map<WebSocket, PlayerState> = new Map();
  private settings: Settings = { ...DEFAULT_SETTINGS };

  constructor(private ctx: DurableObjectState, private env: Env) {}

  // ── HTTP / WS upgrade ────────────────────────────────────────────────────
  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Expected WebSocket upgrade", { status: 426 });
    }

    const pair   = new WebSocketPair();
    const [client, server] = Object.values(pair) as [WebSocket, WebSocket];
    this.ctx.acceptWebSocket(server);

    // Send current room state on connect
    const state = await this.loadState();
    server.send(JSON.stringify({ type: "room_state", ...this.publicState(state) }));
    server.send(JSON.stringify({ type: "leaderboard", entries: await this.loadLeaderboard() }));

    return new Response(null, { status: 101, webSocket: client });
  }

  // ── WebSocket message handler ─────────────────────────────────────────────
  async webSocketMessage(ws: WebSocket, raw: string | ArrayBuffer): Promise<void> {
    let msg: { type: string; [k: string]: unknown };
    try {
      msg = JSON.parse(typeof raw === "string" ? raw : new TextDecoder().decode(raw));
    } catch {
      ws.send(JSON.stringify({ type: "error", message: "Invalid JSON" }));
      return;
    }

    const state = await this.loadState();

    switch (msg.type) {
      case "join": {
        const player: PlayerState = {
          name:      String(msg.playerName ?? "Joueur"),
          chips:     this.settings.startingChips,
          bets:      {},
          connected: true,
        };
        this.players.set(ws, player);
        this.broadcast({ type: "player_joined", player: { name: player.name, chips: player.chips } });
        break;
      }

      case "place_bet": {
        const player = this.players.get(ws);
        if (!player || state.phase !== "betting") break;
        const rank   = Number(msg.rank);
        const amount = Number(msg.amount);
        const contre = Boolean(msg.contre);
        if (rank >= 1 && rank <= 13 && amount > 0 && amount <= player.chips) {
          player.bets[String(rank)] = { amount, contre };
          this.broadcast({ type: "bet_updated", playerId: ws.toString(), bets: player.bets });
        }
        break;
      }

      case "remove_bet": {
        const player = this.players.get(ws);
        if (!player || state.phase !== "betting") break;
        delete player.bets[String(msg.rank)];
        this.broadcast({ type: "bet_updated", playerId: ws.toString(), bets: player.bets });
        break;
      }

      case "submit_initials": {
        const player   = this.players.get(ws);
        const initials = String(msg.initials ?? "???").toUpperCase().slice(0, 3);
        if (!player) break;
        await this.addLeaderboardEntry(initials, player.chips, state.turnNumber);
        const entries = await this.loadLeaderboard();
        this.broadcast({ type: "leaderboard", entries });
        break;
      }

      case "ping":
        ws.send(JSON.stringify({ type: "pong", ts: msg.ts }));
        break;
    }
  }

  webSocketClose(ws: WebSocket): void {
    const player = this.players.get(ws);
    if (player) {
      player.connected = false;
      this.broadcast({ type: "player_left", playerName: player.name });
      this.players.delete(ws);
    }
  }

  webSocketError(_ws: WebSocket, _err: unknown): void {}

  // ── Game logic helpers ────────────────────────────────────────────────────

  private async loadState(): Promise<GameState> {
    const saved = await this.ctx.storage.get<GameState>("state");
    if (saved) return saved;
    return this.freshState();
  }

  private async saveState(s: GameState): Promise<void> {
    await this.ctx.storage.put("state", s);
  }

  private freshState(): GameState {
    const deck = this.buildShuffledDeck();
    const soda = deck.shift()!;
    return {
      phase:        "betting",
      turnNumber:   0,
      bankChips:    this.settings.bankChips,
      deckCards:    deck,
      cardsDealt:   [],
      tableau:      {},
      sodaCard:     soda,
      loserCard:    null,
      winnerCard:   null,
      bettingEndsAt: Date.now() + this.settings.bettingTimerMs,
    };
  }

  private buildShuffledDeck(): Card[] {
    const deck: Card[] = [];
    for (let suit = 0; suit < 4; suit++)
      for (let rank = 1; rank <= 13; rank++)
        deck.push({ rank, suit });
    for (let i = deck.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [deck[i], deck[j]] = [deck[j], deck[i]];
    }
    return deck;
  }

  private publicState(s: GameState) {
    return {
      phase:        s.phase,
      turnNumber:   s.turnNumber,
      bankChips:    s.bankChips,
      tableau:      s.tableau,
      sodaCard:     s.sodaCard,
      loserCard:    s.loserCard,
      winnerCard:   s.winnerCard,
      cardsRemaining: s.deckCards.length,
      bettingEndsAt:  s.bettingEndsAt,
      players: Array.from(this.players.values()).map(p => ({
        name: p.name, chips: p.chips, connected: p.connected
      })),
    };
  }

  private async dealTurn(): Promise<void> {
    const state = await this.loadState();
    if (state.deckCards.length < 2) return;

    state.turnNumber++;
    state.loserCard  = state.deckCards.shift()!;
    state.winnerCard = state.deckCards.shift()!;
    state.phase      = "turn_result";

    // Record in tableau
    if (!state.tableau[state.loserCard.rank])  state.tableau[state.loserCard.rank]  = [];
    if (!state.tableau[state.winnerCard.rank]) state.tableau[state.winnerCard.rank] = [];
    state.tableau[state.loserCard.rank].push({ suit: state.loserCard.suit, type: "loser" });
    state.tableau[state.winnerCard.rank].push({ suit: state.winnerCard.suit, type: "winner" });

    const settlements: { playerName: string; net: number }[] = [];
    let bankDelta = 0;
    const isSplit = state.loserCard.rank === state.winnerCard.rank;

    for (const player of this.players.values()) {
      let net = 0;
      for (const [key, bet] of Object.entries(player.bets)) {
        const amount = bet.amount;
        const contre = bet.contre;
        if (key === "cartehaute") {
          const wh = state.winnerCard.rank > state.loserCard.rank;
          net += (isSplit ? -amount / 2 : (contre ? !wh : wh) ? amount : -amount);
          continue;
        }
        const rank = Number(key);
        if (isSplit && rank === state.loserCard.rank) { net -= amount / 2; continue; }
        if (rank === state.winnerCard.rank) net += contre ? -amount : amount;
        else if (rank === state.loserCard.rank) net += contre ? amount : -amount;
      }
      player.chips += net;
      bankDelta    -= net;
      if (net !== 0) settlements.push({ playerName: player.name, net });
      player.bets = {}; // clear bets after settlement
    }

    state.bankChips += bankDelta;
    await this.saveState(state);

    let bankBroken = false;
    let winnerId   = "";
    if (state.bankChips <= 0) {
      state.bankChips = 0;
      bankBroken = true;
      let max = 0;
      for (const [ws, p] of this.players.entries()) {
        if (p.chips > max) { max = p.chips; winnerId = p.name; }
      }
    }

    this.broadcast({
      type:        "turn_result",
      loserCard:   state.loserCard,
      winnerCard:  state.winnerCard,
      settlements,
      newBankChips: state.bankChips,
      turnNumber:   state.turnNumber,
    });

    if (bankBroken) {
      this.broadcast({ type: "bank_broken", winnerId, winnerName: winnerId, finalChips: state.bankChips });
      state.phase = "game_over";
      await this.saveState(state);
      return;
    }

    if (state.deckCards.length <= 1) {
      state.phase = "game_over";
      await this.saveState(state);
      this.broadcast({ type: "game_over", reason: "deck_exhausted" });
      return;
    }

    // Schedule next betting round after a brief pause
    await new Promise(r => setTimeout(r, 3000));
    state.phase        = "betting";
    state.bettingEndsAt = Date.now() + this.settings.bettingTimerMs;
    await this.saveState(state);
    this.broadcast({ type: "room_state", ...this.publicState(state) });

    // Schedule auto-deal
    await new Promise(r => setTimeout(r, this.settings.bettingTimerMs));
    await this.dealTurn();
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  private async loadLeaderboard(): Promise<{ initials: string; chips: number; turn: number; ts: number }[]> {
    return (await this.ctx.storage.get<typeof []>("leaderboard")) ?? [];
  }

  private async addLeaderboardEntry(initials: string, chips: number, turn: number): Promise<void> {
    const lb = await this.loadLeaderboard();
    lb.push({ initials, chips, turn, ts: Date.now() });
    lb.sort((a, b) => b.chips - a.chips);
    while (lb.length > 10) lb.pop();
    await this.ctx.storage.put("leaderboard", lb);
  }

  // ── Broadcast ─────────────────────────────────────────────────────────────

  private broadcast(msg: object): void {
    const text = JSON.stringify(msg);
    for (const ws of this.ctx.getWebSockets()) {
      try { ws.send(text); } catch {}
    }
  }
}

// ---------------------------------------------------------------------------
// Worker entry point
// ---------------------------------------------------------------------------
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin":  "*",
          "Access-Control-Allow-Headers": "Upgrade, Connection",
        },
      });
    }
    const id   = env.PHARAON_ROOM.idFromName("global");
    const room = env.PHARAON_ROOM.get(id);
    return room.fetch(request);
  },
};
