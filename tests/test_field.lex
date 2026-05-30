# tests for src/field.lex

import "std.str" as str

import "../src/field" as field

fn pass() -> Result[Unit, Str] {
  Ok(())
}

fn fail(why :: Str) -> Result[Unit, Str] {
  Err(why)
}

fn assert_true(cond :: Bool, label :: Str) -> Result[Unit, Str] {
  if cond {
    pass()
  } else {
    fail(label)
  }
}

fn sample_fields() -> List[field.FixField] {
  [{ tag: 35, value: "D" }, { tag: 55, value: "MSFT" }, { tag: 54, value: "1" }]
}

fn test_get_existing() -> Result[Unit, Str] {
  match field.get(sample_fields(), 35) {
    None => fail("expected Some"),
    Some(v) => assert_true(v == "D", "msg_type should be D"),
  }
}

fn test_get_missing() -> Result[Unit, Str] {
  match field.get(sample_fields(), 99) {
    None => pass(),
    Some(_) => fail("expected None for missing tag"),
  }
}

fn test_require_ok() -> Result[Unit, Str] {
  match field.require(sample_fields(), 55) {
    Err(_) => fail("expected Ok"),
    Ok(v) => assert_true(v == "MSFT", "symbol"),
  }
}

fn test_require_missing() -> Result[Unit, Str] {
  match field.require(sample_fields(), 999) {
    Ok(_) => fail("expected Err"),
    Err(MissingRequiredTag(t)) => assert_true(t == 999, "tag"),
    Err(_) => fail("wrong error variant"),
  }
}

fn test_has_present() -> Result[Unit, Str] {
  assert_true(field.has(sample_fields(), 35), "has 35")
}

fn test_has_absent() -> Result[Unit, Str] {
  assert_true(not field.has(sample_fields(), 999), "no 999")
}

fn test_set_new() -> Result[Unit, Str] {
  let fs := field.set(sample_fields(), 44, "125.50")
  match field.get(fs, 44) {
    None => fail("expected price to be set"),
    Some(v) => assert_true(v == "125.50", "price"),
  }
}

fn test_set_override() -> Result[Unit, Str] {
  let fs := field.set(sample_fields(), 55, "GOOG")
  match field.get(fs, 55) {
    None => fail("symbol missing"),
    Some(v) => assert_true(v == "GOOG", "overridden symbol"),
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [test_get_existing(), test_get_missing(), test_require_ok(), test_require_missing(), test_has_present(), test_has_absent(), test_set_new(), test_set_override()]
}

fn run_all() -> Int {
  list.fold(suite(), 0, fn (n :: Int, r :: Result[Unit, Str]) -> Int {
    match r {
      Ok(_) => n,
      Err(_) => n + 1,
    }
  })
}

