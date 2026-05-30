# tests for cancel/replace/status/reject FIX 4.4 message types

import "std.list" as list
import "../src/field"   as field
import "../src/tag"     as tag
import "../src/message" as msg
import "../src/v44/enums"                        as en
import "../src/v44/order_cancel_request"         as ocr
import "../src/v44/order_cancel_replace_request" as ocrr
import "../src/v44/order_status_request"         as osr
import "../src/v44/order_cancel_reject"          as ocrej

fn pass() -> Result[Unit, Str] { Ok(()) }
fn fail(why :: Str) -> Result[Unit, Str] { Err(why) }
fn assert_true(cond :: Bool, label :: Str) -> Result[Unit, Str] {
  if cond { pass() } else { fail(label) }
}

# ---- fixtures ---------------------------------------------------

fn sample_ocr() -> ocr.OrderCancelRequest {
  ocr.cancel_request(
    "ORD-002",
    "ORD-001",
    "MSFT",
    Buy,
    100,
    "20260528-10:00:00.000",
    "ALGO01",
    "EXCH01",
    Some("ACC-A"),
    None
  )
}

fn sample_ocrr() -> ocrr.OrderCancelReplaceRequest {
  ocrr.cancel_replace_request(
    "ORD-003",
    "ORD-001",
    "MSFT",
    Buy,
    150,
    Limit,
    Some("124.00"),
    Day,
    "20260528-10:01:00.000",
    "ALGO01",
    "EXCH01",
    Some("ACC-A")
  )
}

fn sample_osr() -> osr.OrderStatusRequest {
  osr.status_request(
    "ORD-001",
    "MSFT",
    Buy,
    Some("EXCH-ID-001"),
    "ALGO01",
    "EXCH01",
    None
  )
}

fn sample_ocrej() -> ocrej.OrderCancelReject {
  ocrej.cancel_reject(
    "ORD-002",
    "ORD-001",
    Some("EXCH-ID-001"),
    StatusNew,
    ResponseToCancel,
    Some(TooLateToCancel),
    "EXCH01",
    "ALGO01",
    Some("order already filled")
  )
}

# ---- order_cancel_request (MsgType=F) ---------------------------

fn test_ocr_msg_type() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  match msg.msg_type(m) {
    None     => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "F", "MsgType=F"),
  }
}

fn test_ocr_orig_cl_ord_id() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  match msg.get(m, tag.orig_cl_ord_id()) {
    None    => fail("OrigClOrdID missing"),
    Some(v) => assert_true(v == "ORD-001", "OrigClOrdID"),
  }
}

fn test_ocr_side() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  match msg.get(m, tag.side()) {
    None    => fail("side missing"),
    Some(v) => assert_true(v == "1", "side Buy"),
  }
}

fn test_ocr_account_present() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  match msg.get(m, tag.account()) {
    None    => fail("account should be present"),
    Some(a) => assert_true(a == "ACC-A", "account"),
  }
}

fn test_ocr_no_text() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  assert_true(not (field.has(m.fields, tag.text())), "no text field")
}

fn test_ocr_roundtrip() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  match ocr.from_fix_message(m) {
    Err(_)  => fail("roundtrip parse failed"),
    Ok(r)   => assert_true(r.orig_cl_ord_id == "ORD-001", "orig_cl_ord_id roundtrip"),
  }
}

fn test_ocr_qty_roundtrip() -> Result[Unit, Str] {
  let m := ocr.to_fix_message(sample_ocr(), 2)
  match ocr.from_fix_message(m) {
    Err(_)  => fail("roundtrip parse failed"),
    Ok(r)   => assert_true(r.order_qty == 100, "order_qty roundtrip"),
  }
}

# ---- order_cancel_replace_request (MsgType=G) -------------------

fn test_ocrr_msg_type() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(sample_ocrr(), 3)
  match msg.msg_type(m) {
    None     => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "G", "MsgType=G"),
  }
}

fn test_ocrr_orig_cl_ord_id() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(sample_ocrr(), 3)
  match msg.get(m, tag.orig_cl_ord_id()) {
    None    => fail("OrigClOrdID missing"),
    Some(v) => assert_true(v == "ORD-001", "OrigClOrdID"),
  }
}

fn test_ocrr_price_present() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(sample_ocrr(), 3)
  match msg.get(m, tag.price()) {
    None    => fail("price missing for Limit order"),
    Some(p) => assert_true(p == "124.00", "price"),
  }
}

fn test_ocrr_ord_type() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(sample_ocrr(), 3)
  match msg.get(m, tag.ord_type()) {
    None    => fail("ord_type missing"),
    Some(t) => assert_true(t == "2", "OrdType=Limit"),
  }
}

fn test_ocrr_roundtrip() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(sample_ocrr(), 3)
  match ocrr.from_fix_message(m) {
    Err(_) => fail("roundtrip parse failed"),
    Ok(r)  => assert_true(r.cl_ord_id == "ORD-003" and r.orig_cl_ord_id == "ORD-001",
                           "cl_ord_id and orig_cl_ord_id roundtrip"),
  }
}

fn test_ocrr_qty_roundtrip() -> Result[Unit, Str] {
  let m := ocrr.to_fix_message(sample_ocrr(), 3)
  match ocrr.from_fix_message(m) {
    Err(_) => fail("roundtrip parse failed"),
    Ok(r)  => assert_true(r.order_qty == 150, "order_qty roundtrip"),
  }
}

# ---- order_status_request (MsgType=H) ---------------------------

fn test_osr_msg_type() -> Result[Unit, Str] {
  let m := osr.to_fix_message(sample_osr(), 4, "20260528-10:02:00.000")
  match msg.msg_type(m) {
    None     => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "H", "MsgType=H"),
  }
}

fn test_osr_order_id_present() -> Result[Unit, Str] {
  let m := osr.to_fix_message(sample_osr(), 4, "20260528-10:02:00.000")
  match msg.get(m, tag.order_id()) {
    None    => fail("order_id should be present"),
    Some(v) => assert_true(v == "EXCH-ID-001", "order_id"),
  }
}

fn test_osr_no_account() -> Result[Unit, Str] {
  let m := osr.to_fix_message(sample_osr(), 4, "20260528-10:02:00.000")
  assert_true(not (field.has(m.fields, tag.account())), "no account field")
}

fn test_osr_roundtrip() -> Result[Unit, Str] {
  let m := osr.to_fix_message(sample_osr(), 4, "20260528-10:02:00.000")
  match osr.from_fix_message(m) {
    Err(_) => fail("roundtrip parse failed"),
    Ok(r)  => assert_true(r.cl_ord_id == "ORD-001", "cl_ord_id roundtrip"),
  }
}

# ---- order_cancel_reject (MsgType=9) ----------------------------

fn test_ocrej_msg_type() -> Result[Unit, Str] {
  let m := ocrej.to_fix_message(sample_ocrej(), 5, "20260528-10:03:00.000")
  match msg.msg_type(m) {
    None     => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "9", "MsgType=9"),
  }
}

fn test_ocrej_cxl_rej_response_to() -> Result[Unit, Str] {
  let m := ocrej.to_fix_message(sample_ocrej(), 5, "20260528-10:03:00.000")
  match msg.get(m, tag.cxl_rej_response_to()) {
    None    => fail("CxlRejResponseTo missing"),
    Some(v) => assert_true(v == "1", "ResponseToCancel"),
  }
}

fn test_ocrej_reason_present() -> Result[Unit, Str] {
  let m := ocrej.to_fix_message(sample_ocrej(), 5, "20260528-10:03:00.000")
  match msg.get(m, tag.cxl_rej_reason()) {
    None    => fail("CxlRejReason should be present"),
    Some(v) => assert_true(v == "0", "TooLateToCancel"),
  }
}

fn test_ocrej_text_present() -> Result[Unit, Str] {
  let m := ocrej.to_fix_message(sample_ocrej(), 5, "20260528-10:03:00.000")
  match msg.get(m, tag.text()) {
    None    => fail("text should be present"),
    Some(v) => assert_true(v == "order already filled", "text"),
  }
}

fn test_ocrej_roundtrip() -> Result[Unit, Str] {
  let m := ocrej.to_fix_message(sample_ocrej(), 5, "20260528-10:03:00.000")
  match ocrej.from_fix_message(m) {
    Err(_) => fail("roundtrip parse failed"),
    Ok(r)  => assert_true(r.orig_cl_ord_id == "ORD-001", "orig_cl_ord_id roundtrip"),
  }
}

# ---- suite ------------------------------------------------------

fn suite() -> List[Result[Unit, Str]] {
  [
    test_ocr_msg_type(),
    test_ocr_orig_cl_ord_id(),
    test_ocr_side(),
    test_ocr_account_present(),
    test_ocr_no_text(),
    test_ocr_roundtrip(),
    test_ocr_qty_roundtrip(),
    test_ocrr_msg_type(),
    test_ocrr_orig_cl_ord_id(),
    test_ocrr_price_present(),
    test_ocrr_ord_type(),
    test_ocrr_roundtrip(),
    test_ocrr_qty_roundtrip(),
    test_osr_msg_type(),
    test_osr_order_id_present(),
    test_osr_no_account(),
    test_osr_roundtrip(),
    test_ocrej_msg_type(),
    test_ocrej_cxl_rej_response_to(),
    test_ocrej_reason_present(),
    test_ocrej_text_present(),
    test_ocrej_roundtrip(),
  ]
}

fn run_all() -> Int {
  list.fold(suite(), 0,
    fn (n :: Int, r :: Result[Unit, Str]) -> Int {
      match r { Ok(_) => n, Err(_) => n + 1 }
    })
}
