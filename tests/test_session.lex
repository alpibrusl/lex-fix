# tests for src/session/{session,sequence,heartbeat}.lex

import "std.list" as list

import "../src/session/session" as sn

import "../src/session/sequence" as seq

import "../src/session/heartbeat" as hb

import "../src/session/messages" as m

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

# Drive one transition and assert the resulting state name.
fn expect_state(state :: sn.SessionState, event :: sn.SessionEvent, want :: Str) -> Result[Unit, Str] {
  match sn.session_transition(state, event) {
    Err(why) => fail(why),
    Ok(next) => assert_true(sn.state_name(next) == want, "transition target"),
  }
}

fn expect_reject(state :: sn.SessionState, event :: sn.SessionEvent) -> Result[Unit, Str] {
  match sn.session_transition(state, event) {
    Ok(_) => fail("transition should have been rejected"),
    Err(_) => pass(),
  }
}

# ---- session state machine --------------------------------------
fn test_initial_disconnected() -> Result[Unit, Str] {
  assert_true(sn.state_name(sn.initial()) == "Disconnected", "initial state")
}

fn test_connect_logs_in() -> Result[Unit, Str] {
  expect_state(Disconnected(()), Connect(()), "LoggingIn")
}

fn test_logon_ack_active() -> Result[Unit, Str] {
  expect_state(LoggingIn(()), LogonAck(()), "Active")
}

fn test_active_heartbeat_stays_active() -> Result[Unit, Str] {
  expect_state(Active(()), Heartbeat(()), "Active")
}

fn test_active_test_request_stays_active() -> Result[Unit, Str] {
  expect_state(Active(()), TestRequest(()), "Active")
}

fn test_active_logout_logging_out() -> Result[Unit, Str] {
  expect_state(Active(()), Logout(()), "LoggingOut")
}

fn test_logging_out_logout_disconnects() -> Result[Unit, Str] {
  expect_state(LoggingOut(()), Logout(()), "Disconnected")
}

fn test_disconnect_from_active() -> Result[Unit, Str] {
  expect_state(Active(()), Disconnect(()), "Disconnected")
}

fn test_disconnect_from_logging_in() -> Result[Unit, Str] {
  expect_state(LoggingIn(()), Disconnect(()), "Disconnected")
}

fn test_reject_heartbeat_when_disconnected() -> Result[Unit, Str] {
  expect_reject(Disconnected(()), Heartbeat(()))
}

fn test_reject_connect_when_active() -> Result[Unit, Str] {
  expect_reject(Active(()), Connect(()))
}

fn test_reject_logon_ack_when_disconnected() -> Result[Unit, Str] {
  expect_reject(Disconnected(()), LogonAck(()))
}

# ---- sequence numbers -------------------------------------------
fn test_new_store_starts_at_one() -> Result[Unit, Str] {
  let s := seq.new_store()
  assert_true(s.outbound == 1 and s.inbound == 1, "fresh store at 1")
}

fn test_next_seq_returns_and_advances() -> Result[Unit, Str] {
  let r := seq.next_seq(seq.new_store())
  assert_true(r.seq == 1 and r.store.outbound == 2, "next_seq advances outbound")
}

fn test_next_seq_twice() -> Result[Unit, Str] {
  let r1 := seq.next_seq(seq.new_store())
  let r2 := seq.next_seq(r1.store)
  assert_true(r1.seq == 1 and r2.seq == 2 and r2.store.outbound == 3, "monotonic outbound")
}

fn test_record_inbound() -> Result[Unit, Str] {
  let s := seq.record_inbound(seq.new_store(), 5)
  assert_true(s.inbound == 6 and s.outbound == 1, "inbound becomes seq+1")
}

fn test_reset_to_one() -> Result[Unit, Str] {
  let s := seq.reset()
  assert_true(s.outbound == 1 and s.inbound == 1, "reset to 1")
}

fn test_seq_in_order_ok() -> Result[Unit, Str] {
  match seq.validate_incoming_seq(5, 5) {
    Ok(_) => pass(),
    Err(_) => fail("in-order seq should be Ok"),
  }
}

fn test_seq_gap_detected() -> Result[Unit, Str] {
  match seq.validate_incoming_seq(5, 7) {
    Ok(_) => fail("gap should be rejected"),
    Err(SequenceGap(expected, got)) => assert_true(expected == 5 and got == 7, "gap carries expected/got"),
    Err(_) => fail("gap should be SequenceGap"),
  }
}

fn test_seq_too_low_detected() -> Result[Unit, Str] {
  match seq.validate_incoming_seq(5, 3) {
    Ok(_) => fail("too-low should be rejected"),
    Err(SequenceTooLow(expected, got)) => assert_true(expected == 5 and got == 3, "too-low carries expected/got"),
    Err(_) => fail("too-low should be SequenceTooLow"),
  }
}

fn test_is_gap() -> Result[Unit, Str] {
  assert_true(seq.is_gap(5, 7) and not seq.is_gap(5, 3) and not seq.is_gap(5, 5), "is_gap classification")
}

# ---- heartbeat logic --------------------------------------------
fn test_heartbeat_due() -> Result[Unit, Str] {
  assert_true(hb.should_send_heartbeat(30, 30), "heartbeat due at interval")
}

fn test_heartbeat_not_due() -> Result[Unit, Str] {
  assert_true(not hb.should_send_heartbeat(10, 30), "heartbeat not due before interval")
}

fn test_heartbeat_disabled() -> Result[Unit, Str] {
  assert_true(not hb.should_send_heartbeat(100, 0), "interval 0 disables heartbeats")
}

fn test_test_request_due() -> Result[Unit, Str] {
  assert_true(hb.should_send_test_request(31, 30), "test request after interval elapsed")
}

fn test_test_request_not_due() -> Result[Unit, Str] {
  assert_true(not hb.should_send_test_request(30, 30), "test request not due at exactly interval")
}

# TestRequest -> Heartbeat round-trip: the response echoes TestReqID
# and swaps sender/target.
fn test_test_request_round_trip() -> Result[Unit, Str] {
  let tr := m.test_request("TR-1", "ALGO01", "EXCH01")
  let resp := hb.respond_to_test_request(tr)
  match resp.test_req_id {
    None => fail("heartbeat response must echo TestReqID"),
    Some(id) => assert_true(id == "TR-1" and resp.sender_comp_id == "EXCH01" and resp.target_comp_id == "ALGO01", "echo + swap"),
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [test_initial_disconnected(), test_connect_logs_in(), test_logon_ack_active(), test_active_heartbeat_stays_active(), test_active_test_request_stays_active(), test_active_logout_logging_out(), test_logging_out_logout_disconnects(), test_disconnect_from_active(), test_disconnect_from_logging_in(), test_reject_heartbeat_when_disconnected(), test_reject_connect_when_active(), test_reject_logon_ack_when_disconnected(), test_new_store_starts_at_one(), test_next_seq_returns_and_advances(), test_next_seq_twice(), test_record_inbound(), test_reset_to_one(), test_seq_in_order_ok(), test_seq_gap_detected(), test_seq_too_low_detected(), test_is_gap(), test_heartbeat_due(), test_heartbeat_not_due(), test_heartbeat_disabled(), test_test_request_due(), test_test_request_not_due(), test_test_request_round_trip()]
}

fn run_all() -> Int {
  list.fold(suite(), 0, fn (n :: Int, r :: Result[Unit, Str]) -> Int {
    match r {
      Ok(_) => n,
      Err(_) => n + 1,
    }
  })
}

