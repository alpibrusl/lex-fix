# lex-fix — new order single round-trip example
#
# Demonstrates: construct a typed NewOrderSingle → encode to FixMessage
# → run pre-execution conformance → decode back to typed form.
#
# This is the core of the agent-native pre-trade gate: an agent
# constructs a typed order value; the substrate encodes and validates
# it before any exchange connection is touched.

import "std.str"  as str
import "std.list" as list

import "../src/conformance"           as conf
import "../src/message"               as msg
import "../src/tag"                   as tag
import "../src/v44/enums"             as en
import "../src/v44/new_order_single"  as nos

fn make_limit_order() -> nos.NewOrderSingle {
  {
    cl_ord_id:      "ORD-2026-001",
    symbol:         "MSFT",
    side:           Buy,
    order_qty:      100,
    ord_type:       Limit,
    price:          Some("125.50"),
    time_in_force:  Day,
    transact_time:  "20260527-09:30:00.000",
    sender_comp_id: "ALGO01",
    target_comp_id: "EXCH01",
    account:        None,
  }
}

fn make_invalid_order() -> nos.NewOrderSingle {
  # Missing price on a Limit order — conformance should reject this.
  {
    cl_ord_id:      "ORD-2026-002",
    symbol:         "AAPL",
    side:           Sell,
    order_qty:      50,
    ord_type:       Limit,
    price:          None,
    time_in_force:  Gtc,
    transact_time:  "20260527-09:30:01.000",
    sender_comp_id: "ALGO01",
    target_comp_id: "EXCH01",
    account:        Some("ACCT-001"),
  }
}

fn run_valid() -> Str {
  let order   := make_limit_order()
  let fix_msg := nos.to_fix_message(order, 1)
  match conf.validate_new_order(fix_msg) {
    Ok(_)    => "valid limit order accepted by pre-trade gate",
    Err(es)  => str.concat("unexpected rejection: ",
      list.fold(conf.describe_errors(es), "",
        fn (acc :: Str, e :: Str) -> Str {
          if acc == "" { e } else { str.concat(acc, str.concat("; ", e)) }
        })),
  }
}

fn run_invalid() -> Str {
  let order   := make_invalid_order()
  let fix_msg := nos.to_fix_message(order, 2)
  match conf.validate_new_order(fix_msg) {
    Ok(_)   => "unexpected: limit without price should have been rejected",
    Err(es) => str.concat("correctly rejected — violations: ",
      list.fold(conf.describe_errors(es), "",
        fn (acc :: Str, e :: Str) -> Str {
          if acc == "" { e } else { str.concat(acc, str.concat("; ", e)) }
        })),
  }
}

fn symbol_field(fix_msg :: msg.FixMessage) -> Str {
  match msg.get(fix_msg, tag.symbol()) {
    None    => "missing",
    Some(s) => s,
  }
}
