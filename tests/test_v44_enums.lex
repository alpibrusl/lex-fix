# tests for src/v44/enums.lex

import "std.str"        as str
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
