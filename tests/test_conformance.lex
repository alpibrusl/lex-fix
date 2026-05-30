# tests for src/conformance.lex

import "std.str"           as str
import "std.list"          as list
import "../src/field"      as field
import "../src/tag"        as tag
import "../src/message"    as msg
import "../src/conformance" as conf
import "../src/v44/enums"   as en
import "../src/v44/new_order_single"         as nos
import "../src/v44/order_cancel_request"     as ocr
import "../src/v44/order_cancel_replace_request" as ocrr
import "../src/v44/order_status_request"     as osr
import "../src/v44/order_cancel_reject"      as ocrej

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
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

fn test_invalid_side_fails() -> Result[Unit, Str] {
  let base   := valid_nos_message()
  let fields := field.set(base.fields, tag.side(), "X")
  let m      := msg.new(fields)
  match conf.validate_new_order(m) {
    Ok(_)   => fail("invalid side should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
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
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

# ---- validate_order_cancel (MsgType=F) --------------------------

fn valid_ocr_message() -> msg.FixMessage {
  ocr.to_fix_message(
    ocr.cancel_request(
      "ORD-002", "ORD-001", "MSFT", Buy, 100,
      "20260528-10:00:00.000", "ALGO01", "EXCH01", None, None
    ), 2)
}

fn test_valid_cancel_passes() -> Result[Unit, Str] {
  match conf.validate_order_cancel(valid_ocr_message()) {
    Err(_) => fail("valid cancel should pass"),
    Ok(_)  => pass(),
  }
}

fn test_cancel_missing_orig_fails() -> Result[Unit, Str] {
  let base   := valid_ocr_message()
  let fields := list.fold(base.fields, [],
    fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
      if f.tag == tag.orig_cl_ord_id() { acc } else { list.concat(acc, [f]) }
    })
  match conf.validate_order_cancel(msg.new(fields)) {
    Ok(_)   => fail("missing OrigClOrdID should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

fn test_cancel_wrong_msg_type_fails() -> Result[Unit, Str] {
  let base   := valid_ocr_message()
  let fields := field.set(base.fields, tag.msg_type(), "D")
  match conf.validate_order_cancel(msg.new(fields)) {
    Ok(_)   => fail("wrong MsgType should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

# ---- validate_order_cancel_replace (MsgType=G) ------------------

fn valid_ocrr_message() -> msg.FixMessage {
  ocrr.to_fix_message(
    ocrr.cancel_replace_request(
      "ORD-003", "ORD-001", "MSFT", Buy, 150, Limit,
      Some("124.00"), Day, "20260528-10:01:00.000", "ALGO01", "EXCH01", None
    ), 3)
}

fn test_valid_replace_passes() -> Result[Unit, Str] {
  match conf.validate_order_cancel_replace(valid_ocrr_message()) {
    Err(_) => fail("valid replace should pass"),
    Ok(_)  => pass(),
  }
}

fn test_replace_limit_without_price_fails() -> Result[Unit, Str] {
  let base   := valid_ocrr_message()
  let fields := list.fold(base.fields, [],
    fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
      if f.tag == tag.price() { acc } else { list.concat(acc, [f]) }
    })
  match conf.validate_order_cancel_replace(msg.new(fields)) {
    Ok(_)   => fail("Limit without price should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

fn test_replace_market_no_price_ok() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(
    ocrr.cancel_replace_request(
      "ORD-004", "ORD-001", "MSFT", Sell, 200, Market,
      None, Day, "20260528-10:02:00.000", "ALGO01", "EXCH01", None
    ), 4)
  match conf.validate_order_cancel_replace(m) {
    Err(_) => fail("Market without price should pass"),
    Ok(_)  => pass(),
  }
}

# ---- validate_order_status (MsgType=H) --------------------------

fn valid_osr_message() -> msg.FixMessage {
  osr.to_fix_message(
    osr.status_request("ORD-001", "MSFT", Buy, None, "ALGO01", "EXCH01", None),
    5, "20260528-10:03:00.000")
}

fn test_valid_status_passes() -> Result[Unit, Str] {
  match conf.validate_order_status(valid_osr_message()) {
    Err(_) => fail("valid status request should pass"),
    Ok(_)  => pass(),
  }
}

fn test_status_missing_side_fails() -> Result[Unit, Str] {
  let base   := valid_osr_message()
  let fields := list.fold(base.fields, [],
    fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
      if f.tag == tag.side() { acc } else { list.concat(acc, [f]) }
    })
  match conf.validate_order_status(msg.new(fields)) {
    Ok(_)   => fail("missing side should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

# ---- validate_order_cancel_reject (MsgType=9) -------------------

fn valid_ocrej_message() -> msg.FixMessage {
  ocrej.to_fix_message(
    ocrej.cancel_reject(
      "ORD-002", "ORD-001", None, StatusNew,
      ResponseToCancel, None, "EXCH01", "ALGO01", None
    ), 6, "20260528-10:04:00.000")
}

fn test_valid_cancel_reject_passes() -> Result[Unit, Str] {
  match conf.validate_order_cancel_reject(valid_ocrej_message()) {
    Err(_) => fail("valid cancel reject should pass"),
    Ok(_)  => pass(),
  }
}

fn test_cancel_reject_missing_response_to_fails() -> Result[Unit, Str] {
  let base   := valid_ocrej_message()
  let fields := list.fold(base.fields, [],
    fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
      if f.tag == tag.cxl_rej_response_to() { acc } else { list.concat(acc, [f]) }
    })
  match conf.validate_order_cancel_reject(msg.new(fields)) {
    Ok(_)   => fail("missing CxlRejResponseTo should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

fn test_cancel_reject_invalid_response_to_fails() -> Result[Unit, Str] {
  let base   := valid_ocrej_message()
  let fields := field.set(base.fields, tag.cxl_rej_response_to(), "9")
  match conf.validate_order_cancel_reject(msg.new(fields)) {
    Ok(_)   => fail("invalid CxlRejResponseTo should fail"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

# ---- validate_cancel_replace_against (cross-message) ------------
# A replace must preserve Side (54) and Symbol (55) of the original
# order. The original is a NewOrderSingle (Buy MSFT); the replace
# amends qty/price but must not flip Side or change Symbol.

fn test_replace_same_side_passes() -> Result[Unit, Str] {
  let orig    := valid_nos_message()          # Buy MSFT
  let replace := valid_ocrr_message()         # Buy MSFT, amended qty/price
  match conf.validate_cancel_replace_against(orig, replace) {
    Err(_) => fail("replace preserving Side/Symbol should pass"),
    Ok(_)  => pass(),
  }
}

fn test_replace_changes_side_fails() -> Result[Unit, Str] {
  let orig    := valid_nos_message()          # Buy
  let flipped := ocrr.to_fix_message(
    ocrr.cancel_replace_request(
      "ORD-003", "ORD-001", "MSFT", Sell, 150, Limit,
      Some("124.00"), Day, "20260528-10:01:00.000", "ALGO01", "EXCH01", None
    ), 3)
  match conf.validate_cancel_replace_against(orig, flipped) {
    Ok(_)   => fail("replace that flips Side should be rejected"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

fn test_replace_changes_symbol_fails() -> Result[Unit, Str] {
  let orig     := valid_nos_message()         # MSFT
  let resymbol := ocrr.to_fix_message(
    ocrr.cancel_replace_request(
      "ORD-003", "ORD-001", "AAPL", Buy, 150, Limit,
      Some("124.00"), Day, "20260528-10:01:00.000", "ALGO01", "EXCH01", None
    ), 3)
  match conf.validate_cancel_replace_against(orig, resymbol) {
    Ok(_)   => fail("replace that changes Symbol should be rejected"),
    Err(es) => assert_true(list.len(es) > 0, "has errors"),
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [
    test_replace_same_side_passes(),
    test_replace_changes_side_fails(),
    test_replace_changes_symbol_fails(),
    test_valid_order_passes(),
    test_missing_symbol_fails(),
    test_invalid_side_fails(),
    test_limit_without_price_fails(),
    test_valid_cancel_passes(),
    test_cancel_missing_orig_fails(),
    test_cancel_wrong_msg_type_fails(),
    test_valid_replace_passes(),
    test_replace_limit_without_price_fails(),
    test_replace_market_no_price_ok(),
    test_valid_status_passes(),
    test_status_missing_side_fails(),
    test_valid_cancel_reject_passes(),
    test_cancel_reject_missing_response_to_fails(),
    test_cancel_reject_invalid_response_to_fails(),
  ]
}

fn run_all() -> Int {
  list.fold(suite(), 0,
    fn (n :: Int, r :: Result[Unit, Str]) -> Int {
      match r { Ok(_) => n, Err(_) => n + 1 }
    })
}
