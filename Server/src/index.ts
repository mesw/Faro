export interface Env {
  COUNTER_ROOM: DurableObjectNamespace;
}

// ---------------------------------------------------------------------------
// Durable Object — one instance shared by all connected clients ("global" room)
// Uses the WebSocket Hibernation API so the DO can sleep between messages.
// ---------------------------------------------------------------------------
export class CounterRoom implements DurableObject {
  constructor(private ctx: DurableObjectState, private env: Env) {}

  // ------------------------------------------------------------------
  // HTTP / WebSocket upgrade entry point
  // ------------------------------------------------------------------
  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Expected WebSocket upgrade", { status: 426 });
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair) as [WebSocket, WebSocket];

    // Hibernation API — Cloudflare manages the socket lifecycle
    this.ctx.acceptWebSocket(server);

    // Sync current counter and leader to the new client immediately
    const [counter, leader] = await Promise.all([
      this.ctx.storage.get<number>("counter"),
      this.ctx.storage.get<string>("leader"),
    ]);
    server.send(JSON.stringify({ type: "counter", value: counter ?? 0, leader: leader ?? "" }));

    return new Response(null, { status: 101, webSocket: client });
  }

  // ------------------------------------------------------------------
  // WebSocket Hibernation handlers
  // ------------------------------------------------------------------
  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer): Promise<void> {
    let data: { type: string; initials?: string };
    try {
      data = JSON.parse(typeof message === "string" ? message : new TextDecoder().decode(message));
    } catch {
      ws.send(JSON.stringify({ type: "error", message: "Invalid JSON" }));
      return;
    }

    if (data.type === "increment" && typeof data.initials === "string") {
      const counter = ((await this.ctx.storage.get<number>("counter")) ?? 0) + 1;
      await this.ctx.storage.put("counter", counter);
      await this.ctx.storage.put("leader", data.initials);
      this.broadcast({ type: "counter", value: counter, leader: data.initials });
    }
  }

  webSocketClose(_ws: WebSocket, _code: number, _reason: string): void {
    // Hibernation handles cleanup; nothing extra needed
  }

  webSocketError(_ws: WebSocket, _error: unknown): void {
    // Errors are logged automatically by the runtime
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  private broadcast(msg: object): void {
    const text = JSON.stringify(msg);
    for (const ws of this.ctx.getWebSockets()) {
      try {
        ws.send(text);
      } catch {
        // Socket already closed — hibernation will remove it
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Worker entry point — routes every request to the single "global" room
// ---------------------------------------------------------------------------
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Allow WebSocket upgrades from any origin (tighten for production)
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "Upgrade, Connection",
        },
      });
    }

    const id = env.COUNTER_ROOM.idFromName("global");
    const room = env.COUNTER_ROOM.get(id);
    return room.fetch(request);
  },
};
