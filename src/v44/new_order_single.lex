# lex-fix — FIX 4.4 New Order Single (MsgType=D)
#
# `NewOrderSingle` is a fully-typed representation of a FIX NOS
# message. Callers construct a typed value; `to_fix_message` converts
# it to the flat FixField list for the transport layer (or for
# lex-trail logging). `from_fix_message` parses inbound fields back
# to the typed form.
#
# Prices are carried as strings (FIX wire format) so the module has
# no dependency on lex-money's Decimal → string formatter. Higher-
# level callers that hold a Money value call money_price_str() to
# format the price before constructing a NewOrderSingle.
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

# ---- Typed domain record -----------------------------------------

type NewOrderSingle = {
  cl_ord_id      :: Str,
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

fn new_order(
  cl_ord_id      :: Str,
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
) -> NewOrderSingle {
  {
    cl_ord_id:      cl_ord_id,
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

# ---- Typed → FixMessage ------------------------------------------

fn to_fix_message(nos :: NewOrderSingle, seq_num :: Int) -> msg.FixMessage {
  let header_fields := msg.header(
    tag.mt_new_order_single(),
    nos.sender_comp_id,
    nos.target_comp_id,
    int.to_str(seq_num),
    nos.transact_time
  )
  let body_fields := [
    { tag: tag.cl_ord_id(),    value: nos.cl_ord_id },
    { tag: tag.symbol(),       value: nos.symbol },
    { tag: tag.side(),         value: en.side_to_str(nos.side) },
    { tag: tag.order_qty(),    value: int.to_str(nos.order_qty) },
    { tag: tag.ord_type(),     value: en.ord_type_to_str(nos.ord_type) },
    { tag: tag.time_in_force(), value: en.tif_to_str(nos.time_in_force) },
    { tag: tag.transact_time(), value: nos.transact_time },
  ]
  let with_price := match nos.price {
    None      => body_fields,
    Some(p)   => list.concat(body_fields,
                   [{ tag: tag.price(), value: p }]),
  }
  let with_account := match nos.account {
    None    => with_price,
    Some(a) => list.concat(with_price,
                 [{ tag: tag.account(), value: a }]),
  }
  msg.new(list.concat(header_fields, with_account))
}

# ---- FixMessage → Typed ------------------------------------------
#
# Returns `Err` with a list of all parse failures rather than stopping
# at the first one — callers see every problem at once.

# Parse a FixMessage into a typed NewOrderSingle. Fails fast on the first
# missing required field or unknown enum value, returning Err([error]).
fn from_fix_message(m :: msg.FixMessage) -> Result[NewOrderSingle, List[e.FixError]] {
  let fields := m.fields
  match field.require(fields, tag.cl_ord_id()) {
    Err(err)  => Err([err]),
    Ok(coi)   => match field.require(fields, tag.symbol()) {
      Err(err)  => Err([err]),
      Ok(sym)   => match field.require(fields, tag.side()) {
        Err(err)  => Err([err]),
        Ok(s_str) => match en.side_from_str(s_str) {
          None      => Err([InvalidTagValue(tag.side(), s_str)]),
          Some(s)   => match field.require(fields, tag.ord_type()) {
            Err(err)   => Err([err]),
            Ok(ot_str) => match en.ord_type_from_str(ot_str) {
              None       => Err([InvalidTagValue(tag.ord_type(), ot_str)]),
              Some(ot)   => match field.require(fields, tag.time_in_force()) {
                Err(err)    => Err([err]),
                Ok(tif_str) => match en.tif_from_str(tif_str) {
                  None        => Err([InvalidTagValue(tag.time_in_force(), tif_str)]),
                  Some(tif)   => match field.require(fields, tag.transact_time()) {
                    Err(err) => Err([err]),
                    Ok(tt)   => match field.require(fields, tag.sender_comp_id()) {
                      Err(err)  => Err([err]),
                      Ok(sndr)  => match field.require(fields, tag.target_comp_id()) {
                        Err(err) => Err([err]),
                        Ok(tgt)  => Ok({
                          cl_ord_id:      coi,
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
  }
}
