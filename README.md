# lex-fix

FIX 4.4 protocol adapter for the [Lex language](https://github.com/alpibrusl/lex-lang).

lex-fix turns FIX messages into first-class typed Lex values. Instead of passing stringly-typed tag-value bags through a trading system, an agent constructs a `NewOrderSingle` record with typed fields — `side :: Side`, `ord_type :: OrdType`, `price :: Option[Str]` — and the substrate validates the message before it ever touches an exchange connection.

Built on [lex-money](https://github.com/alpibrusl/lex-money) for monetary values and [lex-schema](https://github.com/alpibrusl/lex-schema) for payload validation. Companion to [lex-trade](https://github.com/alpibrusl/lex-trade), which layers risk limits and pre-trade checks on top of the FIX protocol surface.

Requires **lex-lang 0.9.4+**.

## What it ships

- **`src/tag.lex`** — FIX tag number constants as typed functions.
- **`src/error.lex`** — `FixError` ADT: `MissingRequiredTag`, `InvalidTagValue`, `UnsupportedMsgType`, `ConformanceViolation`, `ParseError`.
- **`src/field.lex`** — `FixField` type and list helpers: `get`, `require`, `has`, `set`, `validate_one_of`.
- **`src/message.lex`** — `FixMessage` type, standard header builder, structural accessors.
- **`src/conformance.lex`** — Pure pre-execution conformance validation. `validate_new_order` checks all required tags, validates Side/OrdType/TimeInForce against the FIX 4.4 enum catalogs, enforces the `Limit → Price required` rule, and returns all violations at once. Sibling validators cover cancel (`validate_order_cancel`), replace (`validate_order_cancel_replace`), status (`validate_order_status`), and reject (`validate_order_cancel_reject`). The cross-message rule `validate_cancel_replace_against` rejects a replace that changes an immutable attribute (Side or Symbol) of the order it amends.
- **`src/v44/enums.lex`** — Strongly-typed ADTs for `Side`, `OrdType`, `TimeInForce`, `ExecType`, `OrdStatus`, `CxlRejReason`, `CxlRejResponseTo` with `to_str`/`from_str` round-trips.
- **`src/v44/new_order_single.lex`** — `NewOrderSingle` (MsgType=D) typed record + `to_fix_message` / `from_fix_message` codec.
- **`src/v44/execution_report.lex`** — `ExecutionReport` (MsgType=8) typed record + codec.
- **`src/v44/order_cancel_request.lex`** — `OrderCancelRequest` (MsgType=F) typed record + codec.
- **`src/v44/order_cancel_replace_request.lex`** — `OrderCancelReplaceRequest` (MsgType=G) typed record + codec.
- **`src/v44/order_status_request.lex`** — `OrderStatusRequest` (MsgType=H) typed record + codec.
- **`src/v44/order_cancel_reject.lex`** — `OrderCancelReject` (MsgType=9) typed record + codec.

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
