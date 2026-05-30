# tests for src/venue.lex + venue-aware conformance in src/conformance.lex

import "std.list" as list

import "../src/field" as field

import "../src/tag" as tag

import "../src/message" as msg

import "../src/conformance" as conf

import "../src/venue" as vn

import "../src/v44/new_order_single" as nos

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

# ---- fixtures ---------------------------------------------------
fn limit_order_msg() -> msg.FixMessage {
  nos.to_fix_message(nos.new_order("ORD-1", "MSFT", Buy(()), 100, Limit(()), Some("125.50"), Day(()), "20260530-09:30:00.000", "ALGO01", "EXCH01", None), 1)
}

fn stop_order_msg() -> msg.FixMessage {
  nos.to_fix_message(nos.new_order("ORD-2", "MSFT", Buy(()), 100, Stop(()), None, Day(()), "20260530-09:30:00.000", "ALGO01", "EXCH01", None), 2)
}

fn small_order_msg() -> msg.FixMessage {
  nos.to_fix_message(nos.new_order("ORD-3", "MSFT", Buy(()), 50, Limit(()), Some("125.50"), Day(()), "20260530-09:30:00.000", "ALGO01", "EXCH01", None), 3)
}

# ---- venue registry ---------------------------------------------
fn test_nyse_profile_forbids_stops() -> Result[Unit, Str] {
  let p := vn.venue_profile(Nyse(()))
  match list.head(p.restrictions) {
    None => fail("NYSE profile should carry a restriction"),
    Some(r) => assert_true(r == "no_stop_orders", "NYSE forbids stop orders"),
  }
}

fn test_venue_from_str_known() -> Result[Unit, Str] {
  assert_true(vn.venue_to_str(vn.venue_from_str("xnys")) == "NYSE" and vn.venue_to_str(vn.venue_from_str("NASDAQ")) == "NASDAQ", "MIC/name resolves to venue")
}

fn test_venue_from_str_unknown() -> Result[Unit, Str] {
  assert_true(vn.venue_to_str(vn.venue_from_str("ZZZ")) == "ZZZ", "unknown venue preserves the raw string")
}

# ---- NYSE: valid order passes, stop order rejected --------------
fn test_nyse_limit_passes() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(limit_order_msg(), vn.venue_profile(Nyse(()))) {
    Err(_) => fail("valid Limit order should pass NYSE conformance"),
    Ok(_) => pass(),
  }
}

fn test_nyse_stop_rejected() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(stop_order_msg(), vn.venue_profile(Nyse(()))) {
    Ok(_) => fail("Stop order should be rejected for NYSE"),
    Err(es) => assert_true(list.len(es) > 0, "has venue errors"),
  }
}

# A venue without the restriction accepts the same stop order.
fn test_nasdaq_stop_ok() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(stop_order_msg(), vn.venue_profile(Nasdaq(()))) {
    Err(_) => fail("Stop order should pass on a venue with no stop restriction"),
    Ok(_) => pass(),
  }
}

# ---- Unknown venue falls back to base FIX 4.4 conformance -------
fn test_unknown_venue_valid_passes() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(limit_order_msg(), vn.venue_profile(vn.venue_from_str("WAT"))) {
    Err(_) => fail("valid order should pass under Unknown venue (base only)"),
    Ok(_) => pass(),
  }
}

fn test_unknown_venue_base_failure_surfaces() -> Result[Unit, Str] {
  let base := limit_order_msg()
  let fields := list.fold(base.fields, [], fn (acc :: List[field.FixField], f :: field.FixField) -> List[field.FixField] {
    if f.tag == tag.symbol() {
      acc
    } else {
      list.concat(acc, [f])
    }
  })
  match conf.validate_new_order_venue(msg.new(fields), vn.venue_profile(vn.venue_from_str("WAT"))) {
    Ok(_) => fail("missing Symbol should fail base conformance"),
    Err(es) => assert_true(list.len(es) > 0, "base errors surface"),
  }
}

# ---- min_qty restriction (synthetic profile) -------------------
fn min_qty_profile() -> vn.VenueProfile {
  { venue: Nasdaq(()), fix_version: "FIX.4.4", custom_tags: [], restrictions: ["min_qty_100"] }
}

fn test_min_qty_rejects_small() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(small_order_msg(), min_qty_profile()) {
    Ok(_) => fail("order below min qty should be rejected"),
    Err(es) => assert_true(list.len(es) > 0, "min qty violation"),
  }
}

fn test_min_qty_accepts_large() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(limit_order_msg(), min_qty_profile()) {
    Err(_) => fail("order at/above min qty should pass"),
    Ok(_) => pass(),
  }
}

# ---- custom required tags (synthetic profile) ------------------
fn custom_tag_profile() -> vn.VenueProfile {
  { venue: Cboe(()), fix_version: "FIX.4.4", custom_tags: [tag.security_exchange()], restrictions: [] }
}

fn test_custom_tag_missing_fails() -> Result[Unit, Str] {
  match conf.validate_new_order_venue(limit_order_msg(), custom_tag_profile()) {
    Ok(_) => fail("missing venue-required tag should fail"),
    Err(es) => assert_true(list.len(es) > 0, "custom tag required"),
  }
}

fn test_custom_tag_present_passes() -> Result[Unit, Str] {
  let with_tag := msg.new(field.set(limit_order_msg().fields, tag.security_exchange(), "XCBO"))
  match conf.validate_new_order_venue(with_tag, custom_tag_profile()) {
    Err(_) => fail("order carrying the venue-required tag should pass"),
    Ok(_) => pass(),
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [test_nyse_profile_forbids_stops(), test_venue_from_str_known(), test_venue_from_str_unknown(), test_nyse_limit_passes(), test_nyse_stop_rejected(), test_nasdaq_stop_ok(), test_unknown_venue_valid_passes(), test_unknown_venue_base_failure_surfaces(), test_min_qty_rejects_small(), test_min_qty_accepts_large(), test_custom_tag_missing_fails(), test_custom_tag_present_passes()]
}

fn run_all() -> Int {
  list.fold(suite(), 0, fn (n :: Int, r :: Result[Unit, Str]) -> Int {
    match r {
      Ok(_) => n,
      Err(_) => n + 1,
    }
  })
}

