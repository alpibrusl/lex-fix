# lex-fix — FIX 4.4 Order Cancel Request (MsgType=F)
#
# Requests cancellation of a previously submitted order identified by
# OrigClOrdId (41). The exchange responds with either an Execution
# Report (cancel confirmed) or an Order Cancel Reject (MsgType=9).
#
# Effects: none.

import "std.str"  as str
import "std.list" as list
import "std.int"  as int

import "../field"   as field
import "../tag"     as tag
import "../error"   as e
import "../message" as msg
import "./enums"    as en

# ---- Typed domain record ----------------------------------------

type OrderCancelRequest = {
  cl_ord_id      :: Str,
  orig_cl_ord_id :: Str,
  symbol         :: Str,
  side           :: en.Side,
  order_qty      :: Int,
  transact_time  :: Str,
  sender_comp_id :: Str,
  target_comp_id :: Str,
  account        :: Option[Str],
  text           :: Option[Str],
}

fn cancel_request(
  cl_ord_id      :: Str,
  orig_cl_ord_id :: Str,
  symbol         :: Str,
  side           :: en.Side,
  order_qty      :: Int,
  transact_time  :: Str,
  sender_comp_id :: Str,
  target_comp_id :: Str,
  account        :: Option[Str],
  text           :: Option[Str]
) -> OrderCancelRequest {
  {
    cl_ord_id:      cl_ord_id,
    orig_cl_ord_id: orig_cl_ord_id,
    symbol:         symbol,
    side:           side,
    order_qty:      order_qty,
    transact_time:  transact_time,
    sender_comp_id: sender_comp_id,
    target_comp_id: target_comp_id,
    account:        account,
    text:           text,
  }
}

# ---- Typed → FixMessage -----------------------------------------

fn to_fix_message(ocr :: OrderCancelRequest, seq_num :: Int) -> msg.FixMessage {
  let header_fields := msg.header(
    tag.mt_order_cancel(),
    ocr.sender_comp_id,
    ocr.target_comp_id,
    int.to_str(seq_num),
    ocr.transact_time
  )
  let body_fields := [
    { tag: tag.cl_ord_id(),      value: ocr.cl_ord_id },
    { tag: tag.orig_cl_ord_id(), value: ocr.orig_cl_ord_id },
    { tag: tag.symbol(),         value: ocr.symbol },
    { tag: tag.side(),           value: en.side_to_str(ocr.side) },
    { tag: tag.order_qty(),      value: int.to_str(ocr.order_qty) },
    { tag: tag.transact_time(),  value: ocr.transact_time },
  ]
  let with_account := match ocr.account {
    None    => body_fields,
    Some(a) => list.concat(body_fields, [{ tag: tag.account(), value: a }]),
  }
  let with_text := match ocr.text {
    None    => with_account,
    Some(t) => list.concat(with_account, [{ tag: tag.text(), value: t }]),
  }
  msg.new(list.concat(header_fields, with_text))
}

# ---- FixMessage → Typed -----------------------------------------

fn from_fix_message(m :: msg.FixMessage) -> Result[OrderCancelRequest, List[e.FixError]] {
  let fields := m.fields
  match field.require(fields, tag.cl_ord_id()) {
    Err(err)   => Err([err]),
    Ok(coi)    => match field.require(fields, tag.orig_cl_ord_id()) {
      Err(err) => Err([err]),
      Ok(ocoi) => match field.require(fields, tag.symbol()) {
        Err(err) => Err([err]),
        Ok(sym)  => match field.require(fields, tag.side()) {
          Err(err)  => Err([err]),
          Ok(s_str) => match en.side_from_str(s_str) {
            None    => Err([InvalidTagValue(tag.side(), s_str)]),
            Some(s) => match field.require(fields, tag.order_qty()) {
              Err(err)  => Err([err]),
              Ok(qty_s) => match field.require(fields, tag.transact_time()) {
                Err(err) => Err([err]),
                Ok(tt)   => match field.require(fields, tag.sender_comp_id()) {
                  Err(err)  => Err([err]),
                  Ok(sndr)  => match field.require(fields, tag.target_comp_id()) {
                    Err(err) => Err([err]),
                    Ok(tgt)  => match str.to_int(qty_s) {
                      None      => Err([InvalidTagValue(tag.order_qty(), qty_s)]),
                      Some(qty) => Ok({
                        cl_ord_id:      coi,
                        orig_cl_ord_id: ocoi,
                        symbol:         sym,
                        side:           s,
                        order_qty:      qty,
                        transact_time:  tt,
                        sender_comp_id: sndr,
                        target_comp_id: tgt,
                        account:        field.get(fields, tag.account()),
                        text:           field.get(fields, tag.text()),
                      }),
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  }
}
