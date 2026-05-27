# tests for src/conformance.lex

import "std.str"           as str
import "std.list"          as list
import "../src/field"      as field
import "../src/tag"        as tag
import "../src/message"    as msg
import "../src/conformance" as conf
import "../src/v44/enums"   as en
import "../src/v44/new_order_single" as nos

fn pass() -> Result[Unit, Str] { Ok(()) }
fn fail(why :: Str) -> Result[Unit, Str] { Err(why) }
fn assert_true(cond :: Bool, label :: Str) -> Result[Unit, Str] {
  if cond { pass() } else { fail(label) }
}

fn valid_nos_message() -> msg.FixMessage {
  let n := {
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
  nos.to_fix_message(n, 1)
}

fn test_valid_order_passes() -> Result[Unit, Str] {
  match conf.validate_new_order(valid_nos_message()) {
    Err(_)  => fail("valid order should pass"),
    Ok(_)   => pass(),
  }
}

fn test_missing_symbol_fails() -> Result[Unit, Str] {
  let base   := valid_nos_message()
  let fields := list.fold(base.fields, [],
    fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
      if f.tag == tag.symbol() { acc }
      else { list.concat(acc, [f]) }
    })
  let m := msg.new(fields)
  match conf.validate_new_order(m) {
    Ok(_)   => fail("missing symbol should fail"),
    Err(es) => assert_true(list.length(es) > 0, "has errors"),
  }
}

fn test_invalid_side_fails() -> Result[Unit, Str] {
  let base   := valid_nos_message()
  let fields := field.set(base.fields, tag.side(), "X")
  let m      := msg.new(fields)
  match conf.validate_new_order(m) {
    Ok(_)   => fail("invalid side should fail"),
    Err(es) => assert_true(list.length(es) > 0, "has errors"),
  }
}

fn test_limit_without_price_fails() -> Result[Unit, Str] {
  let base   := valid_nos_message()
  let fields := list.fold(base.fields, [],
    fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
      if f.tag == tag.price() { acc }
      else { list.concat(acc, [f]) }
    })
  let m := msg.new(fields)
  match conf.validate_new_order(m) {
    Ok(_)   => fail("limit without price should fail"),
    Err(es) => assert_true(list.length(es) > 0, "has errors"),
  }
}
