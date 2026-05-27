# tests for src/v44/enums.lex

import "std.str"        as str
import "std.list"       as list
import "../src/v44/enums" as en

fn pass() -> Result[Unit, Str] { Ok(()) }
fn fail(why :: Str) -> Result[Unit, Str] { Err(why) }
fn assert_true(cond :: Bool, label :: Str) -> Result[Unit, Str] {
  if cond { pass() } else { fail(label) }
}

fn test_side_to_str() -> Result[Unit, Str] {
  assert_true(en.side_to_str(Buy) == "1", "Buy")
}

fn test_side_from_str_buy() -> Result[Unit, Str] {
  match en.side_from_str("1") {
    None    => fail("expected Buy"),
    Some(s) => assert_true(s == Buy, "side Buy"),
  }
}

fn test_side_from_str_unknown() -> Result[Unit, Str] {
  match en.side_from_str("X") {
    None    => pass(),
    Some(_) => fail("expected None for unknown side"),
  }
}

fn test_ord_type_roundtrip() -> Result[Unit, Str] {
  match en.ord_type_from_str(en.ord_type_to_str(Limit)) {
    None    => fail("roundtrip failed"),
    Some(t) => assert_true(t == Limit, "Limit roundtrip"),
  }
}

fn test_ord_type_requires_price_limit() -> Result[Unit, Str] {
  assert_true(en.ord_type_requires_price(Limit), "Limit requires price")
}

fn test_ord_type_requires_price_market() -> Result[Unit, Str] {
  assert_true(not (en.ord_type_requires_price(Market)), "Market no price")
}

fn test_tif_roundtrip() -> Result[Unit, Str] {
  match en.tif_from_str(en.tif_to_str(Ioc)) {
    None    => fail("tif roundtrip failed"),
    Some(t) => assert_true(t == Ioc, "IOC roundtrip"),
  }
}

fn test_exec_type_roundtrip() -> Result[Unit, Str] {
  match en.exec_type_from_str(en.exec_type_to_str(ExecFill)) {
    None    => fail("exec type roundtrip failed"),
    Some(t) => assert_true(t == ExecFill, "Fill roundtrip"),
  }
}

fn test_ord_status_roundtrip() -> Result[Unit, Str] {
  match en.ord_status_from_str(en.ord_status_to_str(StatusNew)) {
    None    => fail("ord status roundtrip failed"),
    Some(s) => assert_true(s == StatusNew, "New roundtrip"),
  }
}

fn test_cxl_rej_reason_roundtrip() -> Result[Unit, Str] {
  match en.cxl_rej_reason_from_str(en.cxl_rej_reason_to_str(UnknownOrder)) {
    None    => fail("cxl_rej_reason roundtrip failed"),
    Some(r) => assert_true(r == UnknownOrder, "UnknownOrder roundtrip"),
  }
}

fn test_cxl_rej_reason_unknown() -> Result[Unit, Str] {
  match en.cxl_rej_reason_from_str("9") {
    None    => pass(),
    Some(_) => fail("expected None for unknown CxlRejReason"),
  }
}

fn test_cxl_rej_reason_all_variants() -> Result[Unit, Str] {
  let t0 := en.cxl_rej_reason_to_str(TooLateToCancel)            == "0"
  let t1 := en.cxl_rej_reason_to_str(UnknownOrder)               == "1"
  let t2 := en.cxl_rej_reason_to_str(BrokerOption)               == "2"
  let t3 := en.cxl_rej_reason_to_str(AlreadyPendingCxlOrReplace) == "3"
  assert_true(t0 and t1 and t2 and t3, "all CxlRejReason variants")
}

fn test_cxl_rej_response_to_roundtrip() -> Result[Unit, Str] {
  match en.cxl_rej_response_to_from_str(en.cxl_rej_response_to_to_str(ResponseToReplace)) {
    None    => fail("CxlRejResponseTo roundtrip failed"),
    Some(r) => assert_true(r == ResponseToReplace, "ResponseToReplace roundtrip"),
  }
}

fn test_cxl_rej_response_to_unknown() -> Result[Unit, Str] {
  match en.cxl_rej_response_to_from_str("9") {
    None    => pass(),
    Some(_) => fail("expected None for unknown CxlRejResponseTo"),
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [
    test_side_to_str(),
    test_side_from_str_buy(),
    test_side_from_str_unknown(),
    test_ord_type_roundtrip(),
    test_ord_type_requires_price_limit(),
    test_ord_type_requires_price_market(),
    test_tif_roundtrip(),
    test_exec_type_roundtrip(),
    test_ord_status_roundtrip(),
    test_cxl_rej_reason_roundtrip(),
    test_cxl_rej_reason_unknown(),
    test_cxl_rej_reason_all_variants(),
    test_cxl_rej_response_to_roundtrip(),
    test_cxl_rej_response_to_unknown(),
  ]
}

fn run_all() -> Int {
  list.fold(suite(), 0,
    fn (n :: Int, r :: Result[Unit, Str]) -> Int {
      match r { Ok(_) => n, Err(_) => n + 1 }
    })
}
