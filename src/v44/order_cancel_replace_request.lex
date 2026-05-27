# lex-fix — FIX 4.4 Order Cancel/Replace Request (MsgType=G)
#
# Modifies a live order: changes price, quantity, or order type.
# The exchange responds with an Execution Report (replace confirmed)
# or an Order Cancel Reject (MsgType=9). A replace that changes
# OrdType from Market to Limit requires a Price field.
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

type OrderCancelReplaceRequest = {
  cl_ord_id      :: Str,
  orig_cl_ord_id :: Str,
  symbol         :: Str,
  side           :: en.Side,
  order_qty      :: Int,
  ord_type       :: en.OrdType,
  price          :: Option[Str],
  time_in_force  :: en.TimeInForce,
  transact_time  :: Str,
  sender_comp_id :: Str,
  target_comp_id :: Str,
  account        :: Option[Str],
}

fn cancel_replace_request(
  cl_ord_id      :: Str,
  orig_cl_ord_id :: Str,
  symbol         :: Str,
  side           :: en.Side,
  order_qty      :: Int,
  ord_type       :: en.OrdType,
  price          :: Option[Str],
  time_in_force  :: en.TimeInForce,
  transact_time  :: Str,
  sender_comp_id :: Str,
  target_comp_id :: Str,
  account        :: Option[Str]
) -> OrderCancelReplaceRequest {
  {
    cl_ord_id:      cl_ord_id,
    orig_cl_ord_id: orig_cl_ord_id,
    symbol:         symbol,
    side:           side,
    order_qty:      order_qty,
    ord_type:       ord_type,
    price:          price,
    time_in_force:  time_in_force,
    transact_time:  transact_time,
    sender_comp_id: sender_comp_id,
    target_comp_id: target_comp_id,
    account:        account,
  }
}

# ---- Typed → FixMessage -----------------------------------------

fn to_fix_message(ocrr :: OrderCancelReplaceRequest, seq_num :: Int) -> msg.FixMessage {
  let header_fields := msg.header(
    tag.mt_order_cancel_replace(),
    ocrr.sender_comp_id,
    ocrr.target_comp_id,
    int.to_str(seq_num),
    ocrr.transact_time
  )
  let body_fields := [
    { tag: tag.cl_ord_id(),      value: ocrr.cl_ord_id },
    { tag: tag.orig_cl_ord_id(), value: ocrr.orig_cl_ord_id },
    { tag: tag.symbol(),         value: ocrr.symbol },
    { tag: tag.side(),           value: en.side_to_str(ocrr.side) },
    { tag: tag.order_qty(),      value: int.to_str(ocrr.order_qty) },
    { tag: tag.ord_type(),       value: en.ord_type_to_str(ocrr.ord_type) },
    { tag: tag.time_in_force(),  value: en.tif_to_str(ocrr.time_in_force) },
    { tag: tag.transact_time(),  value: ocrr.transact_time },
  ]
  let with_price := match ocrr.price {
    None    => body_fields,
    Some(p) => list.concat(body_fields, [{ tag: tag.price(), value: p }]),
  }
  let with_account := match ocrr.account {
    None    => with_price,
    Some(a) => list.concat(with_price, [{ tag: tag.account(), value: a }]),
  }
  msg.new(list.concat(header_fields, with_account))
}

# ---- FixMessage → Typed -----------------------------------------

fn from_fix_message(m :: msg.FixMessage) -> Result[OrderCancelReplaceRequest, List[e.FixError]] {
  let fields := m.fields
  match field.require(fields, tag.cl_ord_id()) {
    Err(err)   => Err([err]),
    Ok(coi)    => match field.require(fields, tag.orig_cl_ord_id()) {
      Err(err)   => Err([err]),
      Ok(ocoi)   => match field.require(fields, tag.symbol()) {
        Err(err) => Err([err]),
        Ok(sym)  => match field.require(fields, tag.side()) {
          Err(err)  => Err([err]),
          Ok(s_str) => match en.side_from_str(s_str) {
            None    => Err([InvalidTagValue(tag.side(), s_str)]),
            Some(s) => match field.require(fields, tag.ord_type()) {
              Err(err)    => Err([err]),
              Ok(ot_str)  => match en.ord_type_from_str(ot_str) {
                None     => Err([InvalidTagValue(tag.ord_type(), ot_str)]),
                Some(ot) => match field.require(fields, tag.time_in_force()) {
                  Err(err)    => Err([err]),
                  Ok(tif_str) => match en.tif_from_str(tif_str) {
                    None      => Err([InvalidTagValue(tag.time_in_force(), tif_str)]),
                    Some(tif) => match field.require(fields, tag.transact_time()) {
                      Err(err) => Err([err]),
                      Ok(tt)   => match field.require(fields, tag.sender_comp_id()) {
                        Err(err)  => Err([err]),
                        Ok(sndr)  => match field.require(fields, tag.target_comp_id()) {
                          Err(err) => Err([err]),
                          Ok(tgt)  => Ok({
                            cl_ord_id:      coi,
                            orig_cl_ord_id: ocoi,
                            symbol:         sym,
                            side:           s,
                            order_qty:      0,
                            ord_type:       ot,
                            price:          field.get(fields, tag.price()),
                            time_in_force:  tif,
                            transact_time:  tt,
                            sender_comp_id: sndr,
                            target_comp_id: tgt,
                            account:        field.get(fields, tag.account()),
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
      },
    },
  }
}
