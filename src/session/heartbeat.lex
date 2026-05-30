# lex-fix — FIX heartbeat / test-request liveness logic
#
# Pure decision functions for the heartbeat mechanism plus the
# TestRequest -> Heartbeat round-trip. Time is passed in as elapsed
# seconds; this module never reads a clock (that is lex-web's job).
#
# Effects: none.

import "./messages" as m

# Send a Heartbeat (0) when no message has been sent for HeartBtInt
# seconds. A HeartBtInt of 0 disables heartbeating.
fn should_send_heartbeat(idle_secs :: Int, heart_bt_int :: Int) -> Bool {
  if heart_bt_int <= 0 {
    false
  } else {
    idle_secs >= heart_bt_int
  }
}

# Probe a possibly-dead counterparty with a TestRequest (1) when
# nothing has been received for longer than HeartBtInt seconds.
fn should_send_test_request(since_recv_secs :: Int, heart_bt_int :: Int) -> Bool {
  if heart_bt_int <= 0 {
    false
  } else {
    since_recv_secs > heart_bt_int
  }
}

# Respond to an inbound TestRequest (1) with a Heartbeat (0) that
# echoes the TestReqID — the liveness round-trip. sender/target are
# swapped so the response is addressed back to the requester.
fn respond_to_test_request(tr :: m.TestRequest) -> m.Heartbeat {
  m.heartbeat(Some(tr.test_req_id), tr.target_comp_id, tr.sender_comp_id)
}

