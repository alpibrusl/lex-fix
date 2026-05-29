# lex-fix — FIX 4.4 Order Status Request (MsgType=H)
#
# Queries the current status of an order. The exchange responds with
# an Execution Report carrying the current OrdStatus. Can be sent
# for any order regardless of state.
#
# Effects: none.

import "std.str" as str

import "std.list" as list

import "std.int" as int

import "../field" as field

import "../tag" as tag

import "../error" as e

import "../message" as msg

import "./enums" as en

# ---- Typed domain record ----------------------------------------
type OrderStatusRequest = { cl_ord_id :: Str, symbol :: Str, side :: en.Side, order_id :: Option[Str], sender_comp_id :: Str, target_comp_id :: Str, account :: Option[Str] }

fn status_request(cl_ord_id :: Str, symbol :: Str, side :: en.Side, order_id :: Option[Str], sender_comp_id :: Str, target_comp_id :: Str, account :: Option[Str]) -> OrderStatusRequest {
  { cl_ord_id: cl_ord_id, symbol: symbol, side: side, order_id: order_id, sender_comp_id: sender_comp_id, target_comp_id: target_comp_id, account: account }
}

# ---- Typed → FixMessage -----------------------------------------
fn to_fix_message(osr :: OrderStatusRequest, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(tag.mt_order_status(), osr.sender_comp_id, osr.target_comp_id, int.to_str(seq_num), sending_time)
  let body_fields := [{ tag: tag.cl_ord_id(), value: osr.cl_ord_id }, { tag: tag.symbol(), value: osr.symbol }, { tag: tag.side(), value: en.side_to_str(osr.side) }]
  let with_order_id := match osr.order_id {
    None => body_fields,
    Some(i) => list.concat(body_fields, [{ tag: tag.order_id(), value: i }]),
  }
  let with_account := match osr.account {
    None => with_order_id,
    Some(a) => list.concat(with_order_id, [{ tag: tag.account(), value: a }]),
  }
  msg.new(list.concat(header_fields, with_account))
}

# ---- FixMessage → Typed -----------------------------------------
fn from_fix_message(m :: msg.FixMessage) -> Result[OrderStatusRequest, List[e.FixError]] {
  let fields := m.fields
  match field.require(fields, tag.cl_ord_id()) {
    Err(err) => Err([err]),
    Ok(coi) => match field.require(fields, tag.symbol()) {
      Err(err) => Err([err]),
      Ok(sym) => match field.require(fields, tag.side()) {
        Err(err) => Err([err]),
        Ok(s_str) => match en.side_from_str(s_str) {
          None => Err([InvalidTagValue(tag.side(), s_str)]),
          Some(s) => match field.require(fields, tag.sender_comp_id()) {
            Err(err) => Err([err]),
            Ok(sndr) => match field.require(fields, tag.target_comp_id()) {
              Err(err) => Err([err]),
              Ok(tgt) => Ok({ cl_ord_id: coi, symbol: sym, side: s, order_id: field.get(fields, tag.order_id()), sender_comp_id: sndr, target_comp_id: tgt, account: field.get(fields, tag.account()) }),
            },
          },
        },
      },
    },
  }
}

