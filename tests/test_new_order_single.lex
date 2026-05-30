# tests for src/v44/new_order_single.lex

import "std.str"                    as str
import "../src/field"               as field
import "../src/tag"                 as tag
import "../src/message"             as msg
import "../src/v44/enums"           as en
import "../src/v44/new_order_single" as nos

fn pass() -> Result[Unit, Str] { Ok(()) }
fn fail(why :: Str) -> Result[Unit, Str] { Err(why) }
fn assert_true(cond :: Bool, label :: Str) -> Result[Unit, Str] {
  if cond { pass() } else { fail(label) }
}

fn sample_nos() -> nos.NewOrderSingle {
  {
    cl_ord_id:      "ORD-001",
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

fn test_to_fix_message_msg_type() -> Result[Unit, Str] {
  let m := nos.to_fix_message(sample_nos(), 1)
  match msg.msg_type(m) {
    None    => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "D", "msg type D"),
  }
}

fn test_to_fix_message_symbol() -> Result[Unit, Str] {
  let m := nos.to_fix_message(sample_nos(), 1)
  match msg.get(m, tag.symbol()) {
    None    => fail("symbol missing"),
    Some(s) => assert_true(s == "MSFT", "symbol"),
  }
}

fn test_to_fix_message_side() -> Result[Unit, Str] {
  let m := nos.to_fix_message(sample_nos(), 1)
  match msg.get(m, tag.side()) {
    None    => fail("side missing"),
    Some(s) => assert_true(s == "1", "side Buy"),
  }
}

fn test_to_fix_message_price() -> Result[Unit, Str] {
  let m := nos.to_fix_message(sample_nos(), 1)
  match msg.get(m, tag.price()) {
    None    => fail("price missing"),
    Some(p) => assert_true(p == "125.50", "price"),
  }
}

fn test_to_fix_message_no_account() -> Result[Unit, Str] {
  let m := nos.to_fix_message(sample_nos(), 1)
  assert_true(not (field.has(m.fields, tag.account())), "no account")
}

fn test_roundtrip_qty() -> Result[Unit, Str] {
  let m := nos.to_fix_message(sample_nos(), 1)
  match nos.from_fix_message(m) {
    Err(_) => fail("roundtrip parse failed"),
    Ok(r)  => assert_true(r.order_qty == 100, "order_qty roundtrip"),
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [
    test_to_fix_message_msg_type(),
    test_to_fix_message_symbol(),
    test_to_fix_message_side(),
    test_to_fix_message_price(),
    test_to_fix_message_no_account(),
    test_roundtrip_qty(),
  ]
}

fn run_all() -> Int {
  list.fold(suite(), 0,
    fn (n :: Int, r :: Result[Unit, Str]) -> Int {
      match r { Ok(_) => n, Err(_) => n + 1 }
    })
}
