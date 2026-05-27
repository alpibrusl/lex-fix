# lex-fix — pre-execution conformance validation
#
# Validates a FixMessage before it is submitted to the market. This
# is the central correctness gate: if `validate_new_order` returns
# `Err`, the order is rejected before it touches any exchange
# connection. The caller is responsible for logging the errors (e.g.
# to lex-trail) and returning a typed rejection to the upstream agent.
#
# Design: pure, no effects. The effectful wrapper that writes to
# lex-trail lives in the domain layer (lex-trade).
#
# Each validation function returns `Result[FixMessage, List[FixError]]`.
# Errors accumulate: a single call reveals *all* violations, not just
# the first one.
#
# Effects: none.

import "std.list" as list

import "./error"   as e
import "./field"   as field
import "./message" as msg
import "./tag"     as tag

# ---- Internal helpers --------------------------------------------

fn add_error(
  errs :: List[e.FixError],
  err  :: e.FixError
) -> List[e.FixError] {
  list.concat(errs, [err])
}

fn check_required(
  fields :: List[field.FixField],
  t      :: Int,
  errs   :: List[e.FixError]
) -> List[e.FixError] {
  if field.has(fields, t) {
    errs
  } else {
    add_error(errs, MissingRequiredTag(t))
  }
}

fn check_one_of(
  fields  :: List[field.FixField],
  t       :: Int,
  allowed :: List[Str],
  errs    :: List[e.FixError]
) -> List[e.FixError] {
  match field.validate_one_of(fields, t, allowed) {
    None      => errs,
    Some(err) => add_error(errs, err),
  }
}

# ---- Public validators -------------------------------------------

# Validate a FIX 4.4 New Order Single (MsgType=D).
# Required tags: 11 (ClOrdID), 55 (Symbol), 54 (Side),
#                60 (TransactTime), 38 (OrderQty), 40 (OrdType).
# If OrdType is Limit (2) or StopLimit (4), tag 44 (Price) is required.
# Side must be "1" (Buy) or "2" (Sell).
# OrdType must be one of "1","2","3","4".
# TimeInForce (59) if present must be one of "0","1","3","4","6".
fn validate_new_order(m :: msg.FixMessage) -> Result[msg.FixMessage, List[e.FixError]] {
  let errs0  := []
  let fields := m.fields

  # Check message type
  let errs1 := match msg.msg_type(m) {
    None     => add_error(errs0, MissingRequiredTag(tag.msg_type())),
    Some(mt) => if mt == tag.mt_new_order_single() {
                  errs0
                } else {
                  add_error(errs0, UnsupportedMsgType(mt))
                },
  }

  # Check required body tags
  let errs2 := check_required(fields, tag.cl_ord_id(),      errs1)
  let errs3 := check_required(fields, tag.symbol(),         errs2)
  let errs4 := check_required(fields, tag.side(),           errs3)
  let errs5 := check_required(fields, tag.transact_time(),  errs4)
  let errs6 := check_required(fields, tag.order_qty(),      errs5)
  let errs7 := check_required(fields, tag.ord_type(),       errs6)

  # Validate Side value
  let errs8 := check_one_of(fields, tag.side(), ["1", "2"], errs7)

  # Validate OrdType value
  let errs9 := check_one_of(fields, tag.ord_type(),
                 ["1", "2", "3", "4"], errs8)

  # If OrdType is Limit(2) or StopLimit(4), Price is required
  let errs10 := match field.get(fields, tag.ord_type()) {
    None    => errs9,
    Some(t) => if t == "2" or t == "4" {
                 check_required(fields, tag.price(), errs9)
               } else {
                 errs9
               },
  }

  # TimeInForce if present must be valid
  let errs11 := check_one_of(fields, tag.time_in_force(),
                  ["0", "1", "3", "4", "6"], errs10)

  if list.len(errs11) == 0 {
    Ok(m)
  } else {
    Err(errs11)
  }
}

# Validate a FIX 4.4 Execution Report (MsgType=8).
fn validate_execution_report(m :: msg.FixMessage) -> Result[msg.FixMessage, List[e.FixError]] {
  let errs0  := []
  let fields := m.fields

  let errs1 := match msg.msg_type(m) {
    None     => add_error(errs0, MissingRequiredTag(tag.msg_type())),
    Some(mt) => if mt == tag.mt_execution_report() {
                  errs0
                } else {
                  add_error(errs0, UnsupportedMsgType(mt))
                },
  }

  let errs2 := check_required(fields, tag.order_id(),   errs1)
  let errs3 := check_required(fields, tag.cl_ord_id(),  errs2)
  let errs4 := check_required(fields, tag.exec_id(),    errs3)
  let errs5 := check_required(fields, tag.exec_type(),  errs4)
  let errs6 := check_required(fields, tag.ord_status(), errs5)
  let errs7 := check_required(fields, tag.symbol(),     errs6)
  let errs8 := check_required(fields, tag.side(),       errs7)
  let errs9 := check_required(fields, tag.order_qty(),  errs8)
  let errs10 := check_required(fields, tag.cum_qty(),   errs9)
  let errs11 := check_required(fields, tag.leaves_qty(), errs10)
  let errs12 := check_required(fields, tag.avg_px(),    errs11)

  if list.len(errs12) == 0 {
    Ok(m)
  } else {
    Err(errs12)
  }
}

# Validate a FIX 4.4 Order Cancel Request (MsgType=F).
# Required tags: 11 (ClOrdID), 41 (OrigClOrdID), 55 (Symbol),
#                54 (Side), 60 (TransactTime), 38 (OrderQty).
# Side must be "1" or "2".
fn validate_order_cancel(m :: msg.FixMessage) -> Result[msg.FixMessage, List[e.FixError]] {
  let errs0  := []
  let fields := m.fields

  let errs1 := match msg.msg_type(m) {
    None     => add_error(errs0, MissingRequiredTag(tag.msg_type())),
    Some(mt) => if mt == tag.mt_order_cancel() { errs0 }
                else { add_error(errs0, UnsupportedMsgType(mt)) },
  }

  let errs2 := check_required(fields, tag.cl_ord_id(),      errs1)
  let errs3 := check_required(fields, tag.orig_cl_ord_id(), errs2)
  let errs4 := check_required(fields, tag.symbol(),         errs3)
  let errs5 := check_required(fields, tag.side(),           errs4)
  let errs6 := check_required(fields, tag.transact_time(),  errs5)
  let errs7 := check_required(fields, tag.order_qty(),      errs6)
  let errs8 := check_one_of(fields, tag.side(), ["1", "2"], errs7)

  if list.len(errs8) == 0 { Ok(m) } else { Err(errs8) }
}

# Validate a FIX 4.4 Order Cancel/Replace Request (MsgType=G).
# Required tags: 11 (ClOrdID), 41 (OrigClOrdID), 55 (Symbol),
#                54 (Side), 60 (TransactTime), 38 (OrderQty), 40 (OrdType).
# If OrdType is Limit(2) or StopLimit(4), Price (44) is required.
fn validate_order_cancel_replace(m :: msg.FixMessage) -> Result[msg.FixMessage, List[e.FixError]] {
  let errs0  := []
  let fields := m.fields

  let errs1 := match msg.msg_type(m) {
    None     => add_error(errs0, MissingRequiredTag(tag.msg_type())),
    Some(mt) => if mt == tag.mt_order_cancel_replace() { errs0 }
                else { add_error(errs0, UnsupportedMsgType(mt)) },
  }

  let errs2 := check_required(fields, tag.cl_ord_id(),      errs1)
  let errs3 := check_required(fields, tag.orig_cl_ord_id(), errs2)
  let errs4 := check_required(fields, tag.symbol(),         errs3)
  let errs5 := check_required(fields, tag.side(),           errs4)
  let errs6 := check_required(fields, tag.transact_time(),  errs5)
  let errs7 := check_required(fields, tag.order_qty(),      errs6)
  let errs8 := check_required(fields, tag.ord_type(),       errs7)
  let errs9 := check_one_of(fields, tag.side(), ["1", "2"], errs8)
  let errs10 := check_one_of(fields, tag.ord_type(), ["1", "2", "3", "4"], errs9)
  let errs11 := match field.get(fields, tag.ord_type()) {
    None    => errs10,
    Some(t) => if t == "2" or t == "4" { check_required(fields, tag.price(), errs10) }
               else { errs10 },
  }

  if list.len(errs11) == 0 { Ok(m) } else { Err(errs11) }
}

# Validate a FIX 4.4 Order Status Request (MsgType=H).
# Required tags: 11 (ClOrdID), 55 (Symbol), 54 (Side).
# Side must be "1" or "2".
fn validate_order_status(m :: msg.FixMessage) -> Result[msg.FixMessage, List[e.FixError]] {
  let errs0  := []
  let fields := m.fields

  let errs1 := match msg.msg_type(m) {
    None     => add_error(errs0, MissingRequiredTag(tag.msg_type())),
    Some(mt) => if mt == tag.mt_order_status() { errs0 }
                else { add_error(errs0, UnsupportedMsgType(mt)) },
  }

  let errs2 := check_required(fields, tag.cl_ord_id(), errs1)
  let errs3 := check_required(fields, tag.symbol(),    errs2)
  let errs4 := check_required(fields, tag.side(),      errs3)
  let errs5 := check_one_of(fields, tag.side(), ["1", "2"], errs4)

  if list.len(errs5) == 0 { Ok(m) } else { Err(errs5) }
}

# Validate a FIX 4.4 Order Cancel Reject (MsgType=9).
# Required tags: 11 (ClOrdID), 41 (OrigClOrdID), 39 (OrdStatus),
#                434 (CxlRejResponseTo).
fn validate_order_cancel_reject(m :: msg.FixMessage) -> Result[msg.FixMessage, List[e.FixError]] {
  let errs0  := []
  let fields := m.fields

  let errs1 := match msg.msg_type(m) {
    None     => add_error(errs0, MissingRequiredTag(tag.msg_type())),
    Some(mt) => if mt == tag.mt_order_cancel_reject() { errs0 }
                else { add_error(errs0, UnsupportedMsgType(mt)) },
  }

  let errs2 := check_required(fields, tag.cl_ord_id(),          errs1)
  let errs3 := check_required(fields, tag.orig_cl_ord_id(),     errs2)
  let errs4 := check_required(fields, tag.ord_status(),         errs3)
  let errs5 := check_required(fields, tag.cxl_rej_response_to(), errs4)
  let errs6 := check_one_of(fields, tag.ord_status(),
                 ["0", "1", "2", "4", "8", "A"], errs5)
  let errs7 := check_one_of(fields, tag.cxl_rej_response_to(),
                 ["1", "2"], errs6)

  if list.len(errs7) == 0 { Ok(m) } else { Err(errs7) }
}

# All violations as a list of human-readable strings.
fn describe_errors(errs :: List[e.FixError]) -> List[Str] {
  list.map(errs, fn (err :: e.FixError) -> Str { e.describe(err) })
}
