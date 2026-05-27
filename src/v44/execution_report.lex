# lex-fix — FIX 4.4 Execution Report (MsgType=8)
#
# Typed representation of an inbound execution report from the
# exchange. `from_fix_message` extracts all required fields;
# `to_fix_message` builds the corresponding FixMessage for
# forwarding or logging.
#
# Effects: none.

import "std.list" as list
import "std.int"  as int

import "../field"   as field
import "../tag"     as tag
import "../error"   as e
import "../message" as msg
import "./enums"    as en

type ExecutionReport = {
  exec_id    :: Str,
  order_id   :: Str,
  cl_ord_id  :: Str,
  exec_type  :: en.ExecType,
  ord_status :: en.OrdStatus,
  symbol     :: Str,
  side       :: en.Side,
  order_qty  :: Str,
  cum_qty    :: Str,
  leaves_qty :: Str,
  avg_px     :: Str,
  last_px    :: Option[Str],
  last_qty   :: Option[Str],
  text       :: Option[Str],
}

fn to_fix_message(
  er          :: ExecutionReport,
  sender_id   :: Str,
  target_id   :: Str,
  seq_num     :: Int,
  timestamp   :: Str
) -> msg.FixMessage {
  let header_fields := msg.header(
    tag.mt_execution_report(),
    sender_id, target_id,
    int.to_str(seq_num), timestamp)
  let body_fields := [
    { tag: tag.exec_id(),    value: er.exec_id },
    { tag: tag.order_id(),   value: er.order_id },
    { tag: tag.cl_ord_id(),  value: er.cl_ord_id },
    { tag: tag.exec_type(),  value: en.exec_type_to_str(er.exec_type) },
    { tag: tag.ord_status(), value: en.ord_status_to_str(er.ord_status) },
    { tag: tag.symbol(),     value: er.symbol },
    { tag: tag.side(),       value: en.side_to_str(er.side) },
    { tag: tag.order_qty(),  value: er.order_qty },
    { tag: tag.cum_qty(),    value: er.cum_qty },
    { tag: tag.leaves_qty(), value: er.leaves_qty },
    { tag: tag.avg_px(),     value: er.avg_px },
  ]
  let with_last_px := match er.last_px {
    None    => body_fields,
    Some(p) => list.concat(body_fields, [{ tag: tag.last_px(), value: p }]),
  }
  let with_last_qty := match er.last_qty {
    None    => with_last_px,
    Some(q) => list.concat(with_last_px, [{ tag: tag.last_qty(), value: q }]),
  }
  let with_text := match er.text {
    None    => with_last_qty,
    Some(t) => list.concat(with_last_qty, [{ tag: tag.text(), value: t }]),
  }
  msg.new(list.concat(header_fields, with_text))
}

fn from_fix_message(m :: msg.FixMessage) -> Result[ExecutionReport, List[e.FixError]] {
  let fields := m.fields
  match field.require(fields, tag.exec_id()) {
    Err(err)  => Err([err]),
    Ok(ei)    => match field.require(fields, tag.order_id()) {
      Err(err)  => Err([err]),
      Ok(oi)    => match field.require(fields, tag.cl_ord_id()) {
        Err(err)  => Err([err]),
        Ok(coi)   => match field.require(fields, tag.exec_type()) {
          Err(err)  => Err([err]),
          Ok(et_s)  => match en.exec_type_from_str(et_s) {
            None      => Err([InvalidTagValue(tag.exec_type(), et_s)]),
            Some(et)  => match field.require(fields, tag.ord_status()) {
              Err(err)  => Err([err]),
              Ok(os_s)  => match en.ord_status_from_str(os_s) {
                None      => Err([InvalidTagValue(tag.ord_status(), os_s)]),
                Some(os)  => match field.require(fields, tag.symbol()) {
                  Err(err)  => Err([err]),
                  Ok(sym)   => match field.require(fields, tag.side()) {
                    Err(err)  => Err([err]),
                    Ok(s_s)   => match en.side_from_str(s_s) {
                      None    => Err([InvalidTagValue(tag.side(), s_s)]),
                      Some(s) => match field.require(fields, tag.order_qty()) {
                        Err(err)  => Err([err]),
                        Ok(oqty)  => match field.require(fields, tag.cum_qty()) {
                          Err(err)  => Err([err]),
                          Ok(cqty)  => match field.require(fields, tag.leaves_qty()) {
                            Err(err)  => Err([err]),
                            Ok(lqty)  => match field.require(fields, tag.avg_px()) {
                              Err(err) => Err([err]),
                              Ok(apx)  => Ok({
                                exec_id:    ei,
                                order_id:   oi,
                                cl_ord_id:  coi,
                                exec_type:  et,
                                ord_status: os,
                                symbol:     sym,
                                side:       s,
                                order_qty:  oqty,
                                cum_qty:    cqty,
                                leaves_qty: lqty,
                                avg_px:     apx,
                                last_px:    field.get(fields, tag.last_px()),
                                last_qty:   field.get(fields, tag.last_qty()),
                                text:       field.get(fields, tag.text()),
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
      },
    },
  }
}
