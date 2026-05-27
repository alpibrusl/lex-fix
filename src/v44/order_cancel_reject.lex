# lex-fix — FIX 4.4 Order Cancel Reject (MsgType=9)
#
# Sent by the exchange when an Order Cancel Request (F) or Order
# Cancel/Replace Request (G) cannot be honored. CxlRejResponseTo (434)
# identifies which request triggered this reject. CxlRejReason (102)
# provides the machine-readable cause.
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

type OrderCancelReject = {
  cl_ord_id           :: Str,
  orig_cl_ord_id      :: Str,
  order_id            :: Option[Str],
  ord_status          :: en.OrdStatus,
  cxl_rej_response_to :: en.CxlRejResponseTo,
  cxl_rej_reason      :: Option[en.CxlRejReason],
  sender_comp_id      :: Str,
  target_comp_id      :: Str,
  text                :: Option[Str],
}

fn cancel_reject(
  cl_ord_id           :: Str,
  orig_cl_ord_id      :: Str,
  order_id            :: Option[Str],
  ord_status          :: en.OrdStatus,
  cxl_rej_response_to :: en.CxlRejResponseTo,
  cxl_rej_reason      :: Option[en.CxlRejReason],
  sender_comp_id      :: Str,
  target_comp_id      :: Str,
  text                :: Option[Str]
) -> OrderCancelReject {
  {
    cl_ord_id:           cl_ord_id,
    orig_cl_ord_id:      orig_cl_ord_id,
    order_id:            order_id,
    ord_status:          ord_status,
    cxl_rej_response_to: cxl_rej_response_to,
    cxl_rej_reason:      cxl_rej_reason,
    sender_comp_id:      sender_comp_id,
    target_comp_id:      target_comp_id,
    text:                text,
  }
}

# ---- Typed → FixMessage -----------------------------------------

fn to_fix_message(ocrej :: OrderCancelReject, seq_num :: Int, sending_time :: Str) -> msg.FixMessage {
  let header_fields := msg.header(
    tag.mt_order_cancel_reject(),
    ocrej.sender_comp_id,
    ocrej.target_comp_id,
    int.to_str(seq_num),
    sending_time
  )
  let body_fields := [
    { tag: tag.cl_ord_id(),          value: ocrej.cl_ord_id },
    { tag: tag.orig_cl_ord_id(),     value: ocrej.orig_cl_ord_id },
    { tag: tag.ord_status(),         value: en.ord_status_to_str(ocrej.ord_status) },
    { tag: tag.cxl_rej_response_to(), value: en.cxl_rej_response_to_to_str(ocrej.cxl_rej_response_to) },
  ]
  let with_order_id := match ocrej.order_id {
    None    => body_fields,
    Some(i) => list.concat(body_fields, [{ tag: tag.order_id(), value: i }]),
  }
  let with_reason := match ocrej.cxl_rej_reason {
    None    => with_order_id,
    Some(r) => list.concat(with_order_id, [{ tag: tag.cxl_rej_reason(), value: en.cxl_rej_reason_to_str(r) }]),
  }
  let with_text := match ocrej.text {
    None    => with_reason,
    Some(t) => list.concat(with_reason, [{ tag: tag.text(), value: t }]),
  }
  msg.new(list.concat(header_fields, with_text))
}

# ---- FixMessage → Typed -----------------------------------------

fn from_fix_message(m :: msg.FixMessage) -> Result[OrderCancelReject, List[e.FixError]] {
  let fields := m.fields
  match field.require(fields, tag.cl_ord_id()) {
    Err(err)   => Err([err]),
    Ok(coi)    => match field.require(fields, tag.orig_cl_ord_id()) {
      Err(err)   => Err([err]),
      Ok(ocoi)   => match field.require(fields, tag.ord_status()) {
        Err(err)    => Err([err]),
        Ok(os_str)  => match en.ord_status_from_str(os_str) {
          None     => Err([InvalidTagValue(tag.ord_status(), os_str)]),
          Some(os) => match field.require(fields, tag.cxl_rej_response_to()) {
            Err(err)    => Err([err]),
            Ok(crt_str) => match en.cxl_rej_response_to_from_str(crt_str) {
              None      => Err([InvalidTagValue(tag.cxl_rej_response_to(), crt_str)]),
              Some(crt) => match field.require(fields, tag.sender_comp_id()) {
                Err(err)  => Err([err]),
                Ok(sndr)  => match field.require(fields, tag.target_comp_id()) {
                  Err(err) => Err([err]),
                  Ok(tgt)  => {
                    let crr := match field.get(fields, tag.cxl_rej_reason()) {
                      None    => None,
                      Some(s) => en.cxl_rej_reason_from_str(s),
                    }
                    Ok({
                      cl_ord_id:           coi,
                      orig_cl_ord_id:      ocoi,
                      order_id:            field.get(fields, tag.order_id()),
                      ord_status:          os,
                      cxl_rej_response_to: crt,
                      cxl_rej_reason:      crr,
                      sender_comp_id:      sndr,
                      target_comp_id:      tgt,
                      text:                field.get(fields, tag.text()),
                    })
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
