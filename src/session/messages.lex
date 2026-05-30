# lex-fix — FIX 4.4 session (administrative) messages
#
# Typed records + codecs for the admin messages that run the session
# layer: Logon (A), Logout (5), Heartbeat (0), TestRequest (1),
# ResendRequest (2), SequenceReset (4). Same to/from codec pattern as
# the application messages in src/v44/. Sequence numbers and sending
# time are supplied by the caller (the session driver in lex-web).
#
# Effects: none.

import "std.str" as str

import "std.list" as list

import "std.int" as int

import "../field" as field

import "../tag" as tag

import "../error" as e

import "../message" as msg

# ---- shared helpers ----------------------------------------------
fn int_or_err(s :: Str, t :: Int) -> Result[Int, e.FixError] {
  match str.to_int(s) {
    Some(n) => Ok(n),
    None => Err(InvalidTagValue(t, s)),
  }
}

fn bool_to_fix(b :: Bool) -> Str {
  if b {
    "Y"
  } else {
    "N"
  }
}

fn bool_from_fix(s :: Str) -> Bool {
  s == "Y"
}

# ---- Logon (MsgType=A) -------------------------------------------
# EncryptMethod (98) and HeartBtInt (108) are required; ResetSeqNumFlag
# (141) is optional and defaults to N.
type Logon = { encrypt_method :: Int, heart_bt_int :: Int, reset_seq_num_flag :: Bool, sender_comp_id :: Str, target_comp_id :: Str }

fn logon(encrypt_method :: Int, heart_bt_int :: Int, reset_seq_num_flag :: Bool, sender_comp_id :: Str, target_comp_id :: Str) -> Logon {
  { encrypt_method: encrypt_method, heart_bt_int: heart_bt_int, reset_seq_num_flag: reset_seq_num_flag, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id }
}

fn logon_to_fix_message(m :: Logon, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_logon(), m.sender_comp_id, m.target_comp_id, int.to_str(seq_num), sending_time)
  let body_fields := [{ tag: tag.encrypt_method(), value: int.to_str(m.encrypt_method) }, { tag: tag.heart_bt_int(), value: int.to_str(m.heart_bt_int) }, { tag: tag.reset_seq_num_flag(), value: bool_to_fix(m.reset_seq_num_flag) }]
  msg.new(list.concat(header_fields, body_fields))
}

fn logon_from_fix_message(fm :: msg.FixMessage) -> Result[Logon, List[e.FixError]] {
  let fields := fm.fields
  match field.require(fields, tag.encrypt_method()) {
    Err(err) => Err([err]),
    Ok(em_s) => match int_or_err(em_s, tag.encrypt_method()) {
      Err(err) => Err([err]),
      Ok(em) => match field.require(fields, tag.heart_bt_int()) {
        Err(err) => Err([err]),
        Ok(hb_s) => match int_or_err(hb_s, tag.heart_bt_int()) {
          Err(err) => Err([err]),
          Ok(hb) => match field.require(fields, tag.sender_comp_id()) {
            Err(err) => Err([err]),
            Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
              Err(err) => Err([err]),
              Ok(tgt) => Ok({ encrypt_method: em, heart_bt_int: hb, reset_seq_num_flag: match field.get(fields, tag.reset_seq_num_flag()) {
                None => false,
                Some(v) => bool_from_fix(v),
              }, sender_comp_id: sndr, target_comp_id: tgt }),
            },
          },
        },
      },
    },
  }
}

# ---- Logout (MsgType=5) ------------------------------------------
# Text (58) is an optional human-readable reason.
type Logout = { text :: Option[Str], sender_comp_id :: Str, target_comp_id :: Str }

fn logout(text :: Option[Str], sender_comp_id :: Str, target_comp_id :: Str) -> Logout {
  { text: text, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id }
}

fn logout_to_fix_message(m :: Logout, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_logout(), m.sender_comp_id, m.target_comp_id, int.to_str(seq_num), sending_time)
  let with_text := match m.text {
    None => header_fields,
    Some(t) => list.concat(header_fields, [{ tag: tag.text(), value: t }]),
  }
  msg.new(with_text)
}

fn logout_from_fix_message(fm :: msg.FixMessage) -> Result[Logout, List[e.FixError]] {
  let fields := fm.fields
  match field.require(fields, tag.sender_comp_id()) {
    Err(err) => Err([err]),
    Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
      Err(err) => Err([err]),
      Ok(tgt) => Ok({ text: field.get(fields, tag.text()), sender_comp_id: sndr, target_comp_id: tgt }),
    },
  }
}

# ---- Heartbeat (MsgType=0) ---------------------------------------
# TestReqID (112) is present only when the heartbeat is a response to a
# TestRequest, in which case it echoes the request's TestReqID.
type Heartbeat = { test_req_id :: Option[Str], sender_comp_id :: Str, target_comp_id :: Str }

fn heartbeat(test_req_id :: Option[Str], sender_comp_id :: Str, target_comp_id :: Str) -> Heartbeat {
  { test_req_id: test_req_id, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id }
}

fn heartbeat_to_fix_message(m :: Heartbeat, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_heartbeat(), m.sender_comp_id, m.target_comp_id, int.to_str(seq_num), sending_time)
  let with_trid := match m.test_req_id {
    None => header_fields,
    Some(id) => list.concat(header_fields, [{ tag: tag.test_req_id(), value: id }]),
  }
  msg.new(with_trid)
}

fn heartbeat_from_fix_message(fm :: msg.FixMessage) -> Result[Heartbeat, List[e.FixError]] {
  let fields := fm.fields
  match field.require(fields, tag.sender_comp_id()) {
    Err(err) => Err([err]),
    Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
      Err(err) => Err([err]),
      Ok(tgt) => Ok({ test_req_id: field.get(fields, tag.test_req_id()), sender_comp_id: sndr, target_comp_id: tgt }),
    },
  }
}

# ---- TestRequest (MsgType=1) -------------------------------------
# TestReqID (112) is required; the counterparty must echo it in a
# Heartbeat to prove liveness.
type TestRequest = { test_req_id :: Str, sender_comp_id :: Str, target_comp_id :: Str }

fn test_request(test_req_id :: Str, sender_comp_id :: Str, target_comp_id :: Str) -> TestRequest {
  { test_req_id: test_req_id, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id }
}

fn test_request_to_fix_message(m :: TestRequest, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_test_request(), m.sender_comp_id, m.target_comp_id, int.to_str(seq_num), sending_time)
  msg.new(list.concat(header_fields, [{ tag: tag.test_req_id(), value: m.test_req_id }]))
}

fn test_request_from_fix_message(fm :: msg.FixMessage) -> Result[TestRequest, List[e.FixError]] {
  let fields := fm.fields
  match field.require(fields, tag.test_req_id()) {
    Err(err) => Err([err]),
    Ok(id) => match field.require(fields, tag.sender_comp_id()) {
      Err(err) => Err([err]),
      Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
        Err(err) => Err([err]),
        Ok(tgt) => Ok({ test_req_id: id, sender_comp_id: sndr, target_comp_id: tgt }),
      },
    },
  }
}

# ---- ResendRequest (MsgType=2) -----------------------------------
# BeginSeqNo (7) and EndSeqNo (16) are required. EndSeqNo=0 means
# "everything from BeginSeqNo onward".
type ResendRequest = { begin_seq_no :: Int, end_seq_no :: Int, sender_comp_id :: Str, target_comp_id :: Str }

fn resend_request(begin_seq_no :: Int, end_seq_no :: Int, sender_comp_id :: Str, target_comp_id :: Str) -> ResendRequest {
  { begin_seq_no: begin_seq_no, end_seq_no: end_seq_no, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id }
}

fn resend_request_to_fix_message(m :: ResendRequest, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_resend_request(), m.sender_comp_id, m.target_comp_id, int.to_str(seq_num), sending_time)
  msg.new(list.concat(header_fields, [{ tag: tag.begin_seq_no(), value: int.to_str(m.begin_seq_no) }, { tag: tag.end_seq_no(), value: int.to_str(m.end_seq_no) }]))
}

fn resend_request_from_fix_message(fm :: msg.FixMessage) -> Result[ResendRequest, List[e.FixError]] {
  let fields := fm.fields
  match field.require(fields, tag.begin_seq_no()) {
    Err(err) => Err([err]),
    Ok(bs_s) => match int_or_err(bs_s, tag.begin_seq_no()) {
      Err(err) => Err([err]),
      Ok(bs) => match field.require(fields, tag.end_seq_no()) {
        Err(err) => Err([err]),
        Ok(es_s) => match int_or_err(es_s, tag.end_seq_no()) {
          Err(err) => Err([err]),
          Ok(es) => match field.require(fields, tag.sender_comp_id()) {
            Err(err) => Err([err]),
            Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
              Err(err) => Err([err]),
              Ok(tgt) => Ok({ begin_seq_no: bs, end_seq_no: es, sender_comp_id: sndr, target_comp_id: tgt }),
            },
          },
        },
      },
    },
  }
}

# ---- SequenceReset (MsgType=4) -----------------------------------
# NewSeqNo (36) is required. GapFillFlag (123) is Y for gap-fill mode
# (in response to a ResendRequest) and N/absent for a hard reset.
type SequenceReset = { new_seq_no :: Int, gap_fill_flag :: Bool, sender_comp_id :: Str, target_comp_id :: Str }

fn sequence_reset(new_seq_no :: Int, gap_fill_flag :: Bool, sender_comp_id :: Str, target_comp_id :: Str) -> SequenceReset {
  { new_seq_no: new_seq_no, gap_fill_flag: gap_fill_flag, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id }
}

fn sequence_reset_to_fix_message(m :: SequenceReset, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_sequence_reset(), m.sender_comp_id, m.target_comp_id, int.to_str(seq_num), sending_time)
  msg.new(list.concat(header_fields, [{ tag: tag.new_seq_no(), value: int.to_str(m.new_seq_no) }, { tag: tag.gap_fill_flag(), value: bool_to_fix(m.gap_fill_flag) }]))
}

fn sequence_reset_from_fix_message(fm :: msg.FixMessage) -> Result[SequenceReset, List[e.FixError]] {
  let fields := fm.fields
  match field.require(fields, tag.new_seq_no()) {
    Err(err) => Err([err]),
    Ok(ns_s) => match int_or_err(ns_s, tag.new_seq_no()) {
      Err(err) => Err([err]),
      Ok(ns) => match field.require(fields, tag.sender_comp_id()) {
        Err(err) => Err([err]),
        Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
          Err(err) => Err([err]),
          Ok(tgt) => Ok({ new_seq_no: ns, gap_fill_flag: match field.get(fields, tag.gap_fill_flag()) {
            None => false,
            Some(v) => bool_from_fix(v),
          }, sender_comp_id: sndr, target_comp_id: tgt }),
        },
      },
    },
  }
}

