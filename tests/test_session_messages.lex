# tests for src/session/messages.lex — admin message codecs

import "std.list" as list

import "../src/tag" as tag

import "../src/message" as msg

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

fn ts() -> Str {
  "20260530-12:00:00.000"
}

# ---- Logon (A) ---------------------------------------------------
fn test_logon_msg_type() -> Result[Unit, Str] {
  let fm := m.logon_to_fix_message(m.logon(0, 30, true, "ALGO01", "EXCH01"), 1, ts())
  match msg.msg_type(fm) {
    None => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "A", "MsgType=A"),
  }
}

fn test_logon_round_trip() -> Result[Unit, Str] {
  let fm := m.logon_to_fix_message(m.logon(0, 30, true, "ALGO01", "EXCH01"), 1, ts())
  match m.logon_from_fix_message(fm) {
    Err(_) => fail("logon roundtrip parse failed"),
    Ok(r) => assert_true(r.encrypt_method == 0 and r.heart_bt_int == 30 and r.reset_seq_num_flag and r.sender_comp_id == "ALGO01" and r.target_comp_id == "EXCH01", "logon fields preserved"),
  }
}

fn test_logon_reset_flag_default() -> Result[Unit, Str] {
  let fm := m.logon_to_fix_message(m.logon(0, 30, false, "ALGO01", "EXCH01"), 1, ts())
  match m.logon_from_fix_message(fm) {
    Err(_) => fail("logon roundtrip parse failed"),
    Ok(r) => assert_true(not r.reset_seq_num_flag, "reset flag false"),
  }
}

# ---- Logout (5) --------------------------------------------------
fn test_logout_round_trip() -> Result[Unit, Str] {
  let fm := m.logout_to_fix_message(m.logout(Some("done for the day"), "ALGO01", "EXCH01"), 9, ts())
  match m.logout_from_fix_message(fm) {
    Err(_) => fail("logout roundtrip parse failed"),
    Ok(r) => match r.text {
      None => fail("text should be present"),
      Some(t) => assert_true(t == "done for the day" and r.sender_comp_id == "ALGO01", "logout text preserved"),
    },
  }
}

fn test_logout_no_text() -> Result[Unit, Str] {
  let fm := m.logout_to_fix_message(m.logout(None, "ALGO01", "EXCH01"), 9, ts())
  match m.logout_from_fix_message(fm) {
    Err(_) => fail("logout roundtrip parse failed"),
    Ok(r) => match r.text {
      None => pass(),
      Some(_) => fail("text should be absent"),
    },
  }
}

# ---- Heartbeat (0) -----------------------------------------------
fn test_heartbeat_msg_type() -> Result[Unit, Str] {
  let fm := m.heartbeat_to_fix_message(m.heartbeat(None, "ALGO01", "EXCH01"), 2, ts())
  match msg.msg_type(fm) {
    None => fail("msg_type missing"),
    Some(mt) => assert_true(mt == "0", "MsgType=0"),
  }
}

fn test_heartbeat_with_test_req_id_round_trip() -> Result[Unit, Str] {
  let fm := m.heartbeat_to_fix_message(m.heartbeat(Some("TR-7"), "ALGO01", "EXCH01"), 2, ts())
  match m.heartbeat_from_fix_message(fm) {
    Err(_) => fail("heartbeat roundtrip parse failed"),
    Ok(r) => match r.test_req_id {
      None => fail("TestReqID should be present"),
      Some(id) => assert_true(id == "TR-7", "TestReqID preserved"),
    },
  }
}

fn test_heartbeat_no_test_req_id() -> Result[Unit, Str] {
  let fm := m.heartbeat_to_fix_message(m.heartbeat(None, "ALGO01", "EXCH01"), 2, ts())
  assert_true(not (msg.get(fm, tag.test_req_id()) == Some("")) and match msg.get(fm, tag.test_req_id()) {
    None => true,
    Some(_) => false,
  }, "no TestReqID emitted")
}

# ---- TestRequest (1) ---------------------------------------------
fn test_test_request_round_trip() -> Result[Unit, Str] {
  let fm := m.test_request_to_fix_message(m.test_request("TR-7", "ALGO01", "EXCH01"), 3, ts())
  match msg.msg_type(fm) {
    None => fail("msg_type missing"),
    Some(mt) => if mt == "1" {
      match m.test_request_from_fix_message(fm) {
        Err(_) => fail("test request roundtrip parse failed"),
        Ok(r) => assert_true(r.test_req_id == "TR-7", "TestReqID preserved"),
      }
    } else {
      fail("MsgType=1 expected")
    },
  }
}

# ---- ResendRequest (2) -------------------------------------------
fn test_resend_request_round_trip() -> Result[Unit, Str] {
  let fm := m.resend_request_to_fix_message(m.resend_request(10, 0, "ALGO01", "EXCH01"), 4, ts())
  match msg.msg_type(fm) {
    None => fail("msg_type missing"),
    Some(mt) => if mt == "2" {
      match m.resend_request_from_fix_message(fm) {
        Err(_) => fail("resend request roundtrip parse failed"),
        Ok(r) => assert_true(r.begin_seq_no == 10 and r.end_seq_no == 0, "begin/end seq preserved"),
      }
    } else {
      fail("MsgType=2 expected")
    },
  }
}

# ---- SequenceReset (4) -------------------------------------------
fn test_sequence_reset_round_trip() -> Result[Unit, Str] {
  let fm := m.sequence_reset_to_fix_message(m.sequence_reset(42, true, "ALGO01", "EXCH01"), 5, ts())
  match msg.msg_type(fm) {
    None => fail("msg_type missing"),
    Some(mt) => if mt == "4" {
      match m.sequence_reset_from_fix_message(fm) {
        Err(_) => fail("sequence reset roundtrip parse failed"),
        Ok(r) => assert_true(r.new_seq_no == 42 and r.gap_fill_flag, "new_seq_no + gap_fill preserved"),
      }
    } else {
      fail("MsgType=4 expected")
    },
  }
}

fn suite() -> List[Result[Unit, Str]] {
  [test_logon_msg_type(), test_logon_round_trip(), test_logon_reset_flag_default(), test_logout_round_trip(), test_logout_no_text(), test_heartbeat_msg_type(), test_heartbeat_with_test_req_id_round_trip(), test_heartbeat_no_test_req_id(), test_test_request_round_trip(), test_resend_request_round_trip(), test_sequence_reset_round_trip()]
}

fn run_all() -> Int {
  list.fold(suite(), 0, fn (n :: Int, r :: Result[Unit, Str]) -> Int {
    match r {
      Ok(_) => n,
      Err(_) => n + 1,
    }
  })
}

