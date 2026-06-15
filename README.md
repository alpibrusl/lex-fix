# lex-fix

[![CI](https://github.com/alpibrusl/lex-fix/actions/workflows/ci.yml/badge.svg)](https://github.com/alpibrusl/lex-fix/actions/workflows/ci.yml)

**Part of the [Lex](https://lexlang.org) project** — Finance · [Manifesto](https://lexlang.org/manifesto) · [All packages](https://lexlang.org)

FIX 4.4 protocol adapter for Lex. Typed messages, compile-time conformance, pure validation.

Instead of passing stringly-typed tag-value bags through a trading system, you construct a `NewOrderSingle` record with typed fields — `side :: Side`, `ord_type :: OrdType`, `price :: Option[Str]` — and the conformance validator checks every required tag and enum value before the message touches an exchange connection.

All validation is **pure**: no network calls, no clock reads, no side effects. The effect-edge is the caller's responsibility.

---

## Modules

### Protocol messages (v44)

| Module | FIX MsgType | Record |
|---|---|---|
| `v44/new_order_single.lex` | D | `NewOrderSingle` |
| `v44/execution_report.lex` | 8 | `ExecutionReport` |
| `v44/order_cancel_request.lex` | F | `OrderCancelRequest` |
| `v44/order_cancel_replace_request.lex` | G | `OrderCancelReplaceRequest` |
| `v44/order_status_request.lex` | H | `OrderStatusRequest` |
| `v44/order_cancel_reject.lex` | 9 | `OrderCancelReject` |

Each module has a typed record, a `to_fix_message` builder, and a `from_fix_message` parser.

### `conformance` — pre-execution validation

```lex
import "lex-fix/src/conformance" as conf

match conf.validate_new_order(fix_msg) {
  Err(violations) => # all failures returned at once, never one at a time
  Ok(validated)   => # proceed to exchange transport
}
```

Validates required tags, FIX 4.4 enum values, `Limit → Price required` rule. Venue-aware variant: `validate_new_order_venue(msg, Nyse)` layers NYSE-specific restrictions (e.g. stop orders banned).

### `venue` — exchange registry

`Nyse`, `Nasdaq`, `Lse`, `Euronext`, `Cboe`, `Unknown`. Each venue has a `VenueProfile` with restriction tokens: `no_stop_orders`, `no_market_orders`, `min_qty_<N>`.

### `v44/enums` — typed ADTs

`Side`, `OrdType`, `TimeInForce`, `ExecType`, `OrdStatus`, `CxlRejReason` — all with `to_str`/`from_str` round-trips.

### Session layer (`session/`)

Pure FIX session state machine — logon handshake, sequence-number discipline, heartbeating. No TCP; transport lives at the server layer.

- `session.lex` — `SessionState × SessionEvent → next_state`
- `sequence.lex` — `SeqStore` with `next_seq`, `record_inbound`, `validate_incoming_seq`
- `heartbeat.lex` — `should_send_heartbeat`, `respond_to_test_request`
- `messages.lex` — typed records for Logon (A), Logout (5), Heartbeat (0), TestRequest (1), ResendRequest (2), SequenceReset (4)

---

## Usage

```lex
import "lex-fix/src/v44/enums"            as en
import "lex-fix/src/v44/new_order_single" as nos
import "lex-fix/src/conformance"          as conf

let order   := nos.new_order("ORD-001", "MSFT", Buy(()), 100,
                 Limit(()), Some("125.50"), Day(()),
                 "20260601-09:30:00.000", "ALGO01", "EXCH01", None)
let fix_msg := nos.to_fix_message(order, 1)

match conf.validate_new_order(fix_msg) {
  Err(violations) => # typed list of FixError — log, surface to agent
  Ok(_)           => # submit to exchange session
}
```

---

## In the stack

```
lex-money
    ↓
lex-fix  ←  protocol and conformance layer
    ↓
lex-positions · lex-trade · lex-sor · lex-finance · lex-oms
```

---

## Install

```toml
[dependencies]
"lex-fix" = { git = "https://github.com/alpibrusl/lex-fix" }
```
