# lex-fix

FIX 4.4 protocol adapter for the [Lex language](https://github.com/alpibrusl/lex-lang).

lex-fix turns FIX messages into first-class typed Lex values. Instead of passing stringly-typed tag-value bags through a trading system, an agent constructs a `NewOrderSingle` record with typed fields — `side :: Side`, `ord_type :: OrdType`, `price :: Option[Str]` — and the substrate validates the message before it ever touches an exchange connection.

Built on [lex-money](https://github.com/alpibrusl/lex-money) for monetary values and [lex-schema](https://github.com/alpibrusl/lex-schema) for payload validation. Companion to [lex-trade](https://github.com/alpibrusl/lex-trade), which layers risk limits and pre-trade checks on top of the FIX protocol surface.

Requires **lex-lang 0.9.4+**.

## What it ships

- **`src/tag.lex`** — FIX tag number constants as typed functions.
- **`src/error.lex`** — `FixError` ADT: `MissingRequiredTag`, `InvalidTagValue`, `UnsupportedMsgType`, `ConformanceViolation`, `ParseError`, `SequenceGap`, `SequenceTooLow`.
- **`src/field.lex`** — `FixField` type and list helpers: `get`, `require`, `has`, `set`, `validate_one_of`.
- **`src/message.lex`** — `FixMessage` type, standard header builder, structural accessors.
- **`src/conformance.lex`** — Pure pre-execution conformance validation. `validate_new_order` checks all required tags, validates Side/OrdType/TimeInForce against the FIX 4.4 enum catalogs, enforces the `Limit → Price required` rule, and returns all violations at once. Sibling validators cover cancel (`validate_order_cancel`), replace (`validate_order_cancel_replace`), status (`validate_order_status`), and reject (`validate_order_cancel_reject`). The cross-message rule `validate_cancel_replace_against` rejects a replace that changes an immutable attribute (Side or Symbol) of the order it amends. `validate_new_order_venue` layers a venue profile on top of base conformance (see `src/venue.lex`).
- **`src/venue.lex`** — venue registry. `Venue` (`Nyse`/`Nasdaq`/`Lse`/`Euronext`/`Cboe`/`Unknown(Str)`) and `VenueProfile` (fix version, custom required tags, restriction tokens). `venue_profile` returns each venue's profile; `venue_from_str` resolves a name/MIC code (anything unrecognized → `Unknown`, which falls back to base FIX 4.4). Recognized restriction tokens: `no_stop_orders`, `no_market_orders`, `min_qty_<N>`. (NYSE forbids stop orders, reflecting its 2016 removal of that order type.)
- **`src/v44/enums.lex`** — Strongly-typed ADTs for `Side`, `OrdType`, `TimeInForce`, `ExecType`, `OrdStatus`, `CxlRejReason`, `CxlRejResponseTo` with `to_str`/`from_str` round-trips.
- **`src/v44/new_order_single.lex`** — `NewOrderSingle` (MsgType=D) typed record + `to_fix_message` / `from_fix_message` codec.
- **`src/v44/execution_report.lex`** — `ExecutionReport` (MsgType=8) typed record + codec.
- **`src/v44/order_cancel_request.lex`** — `OrderCancelRequest` (MsgType=F) typed record + codec.
- **`src/v44/order_cancel_replace_request.lex`** — `OrderCancelReplaceRequest` (MsgType=G) typed record + codec.
- **`src/v44/order_status_request.lex`** — `OrderStatusRequest` (MsgType=H) typed record + codec.
- **`src/v44/order_cancel_reject.lex`** — `OrderCancelReject` (MsgType=9) typed record + codec.

### Session layer (`src/session/`)

The session layer owns the FIX session *protocol* — the logon handshake, sequence-number discipline, and heartbeating. It is pure: the actual TCP transport lives in lex-web, so nothing here opens a socket.

- **`src/session/session.lex`** — pure session state machine. `SessionState` (`Disconnected`/`LoggingIn`/`Active`/`LoggingOut`) × `SessionEvent` (`Connect`/`LogonAck`/`Heartbeat`/`TestRequest`/`Logout`/`Disconnect`) → `session_transition`, which returns the next state or a descriptive rejection. A `Disconnect` is honoured from any state.
- **`src/session/sequence.lex`** — `SeqStore` (outbound/inbound counters). `next_seq` (pure: returns the number to send + advanced store), `record_inbound`, `reset`, and `validate_incoming_seq`, which classifies an inbound `MsgSeqNum` as in-order, a recoverable `SequenceGap` (→ ResendRequest), or a fatal `SequenceTooLow`.
- **`src/session/messages.lex`** — typed records + codecs for the admin messages: `Logon` (A), `Logout` (5), `Heartbeat` (0), `TestRequest` (1), `ResendRequest` (2), `SequenceReset` (4).
- **`src/session/heartbeat.lex`** — pure liveness logic: `should_send_heartbeat`, `should_send_test_request`, and `respond_to_test_request`, which builds the Heartbeat that echoes an inbound TestRequest's `TestReqID`.

## Usage

```lex
import "lex-fix/v44/enums"           as en
import "lex-fix/v44/new_order_single" as nos
import "lex-fix/conformance"          as conf
import "lex-fix/message"              as msg

let order := nos.new_order(
  "ORD-001", "MSFT", Buy, 100,
  Limit, Some("125.50"), Day,
  "20260527-09:30:00.000",
  "ALGO01", "EXCH01", None)

let fix_msg := nos.to_fix_message(order, 1)

match conf.validate_new_order(fix_msg) {
  Err(violations) => # reject; log violations to lex-trail
  Ok(validated)   => # submit to exchange transport
}
```

## Design note

The conformance validator is **pure** — it takes a `FixMessage` and returns a `Result`. No network calls, no clock reads, no side effects. The effect-edge (logging rejections to lex-trail, connecting to an exchange session) is the caller's responsibility. This makes the validation layer trivially testable and composable.

---

Built under the principles of [Trust Without Comprehension](https://alpibru.com/manifesto).
