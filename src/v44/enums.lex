# lex-fix — FIX 4.4 strongly-typed enum ADTs
#
# The FIX protocol uses single-character or short-string codes for
# enumerated fields. This module replaces stringly-typed field values
# with ADTs. Every variant maps to exactly one wire string; the
# from_str functions return Option so callers can handle unknown values.
#
# Effects: none.
# ---- Side (tag 54) -----------------------------------------------

type Side = Buy(Unit) | Sell(Unit)

fn side_to_str(s :: Side) -> Str
  examples {
    side_to_str(Buy(())) => "1",
    side_to_str(Sell(())) => "2"
  }
{
  match s {
    Buy(_) => "1",
    Sell(_) => "2",
  }
}

fn side_from_str(s :: Str) -> Option[Side] {
  if s == "1" {
    Some(Buy(()))
  } else {
    if s == "2" {
      Some(Sell(()))
    } else {
      None
    }
  }
}

# ---- OrdType (tag 40) --------------------------------------------
type OrdType = Market(Unit) | Limit(Unit) | Stop(Unit) | StopLimit(Unit)

fn ord_type_to_str(t :: OrdType) -> Str
  examples {
    ord_type_to_str(Market(())) => "1",
    ord_type_to_str(Limit(())) => "2",
    ord_type_to_str(Stop(())) => "3",
    ord_type_to_str(StopLimit(())) => "4"
  }
{
  match t {
    Market(_) => "1",
    Limit(_) => "2",
    Stop(_) => "3",
    StopLimit(_) => "4",
  }
}

fn ord_type_from_str(s :: Str) -> Option[OrdType] {
  if s == "1" {
    Some(Market(()))
  } else {
    if s == "2" {
      Some(Limit(()))
    } else {
      if s == "3" {
        Some(Stop(()))
      } else {
        if s == "4" {
          Some(StopLimit(()))
        } else {
          None
        }
      }
    }
  }
}

fn ord_type_requires_price(t :: OrdType) -> Bool {
  match t {
    Limit(_) => true,
    StopLimit(_) => true,
    Market(_) => false,
    Stop(_) => false,
  }
}

# ---- TimeInForce (tag 59) ----------------------------------------
type TimeInForce = Day(Unit) | Gtc(Unit) | Ioc(Unit) | Fok(Unit) | AtClose(Unit)

fn tif_to_str(t :: TimeInForce) -> Str
  examples {
    tif_to_str(Day(())) => "0",
    tif_to_str(Gtc(())) => "1",
    tif_to_str(Ioc(())) => "3",
    tif_to_str(Fok(())) => "4"
  }
{
  match t {
    Day(_) => "0",
    Gtc(_) => "1",
    Ioc(_) => "3",
    Fok(_) => "4",
    AtClose(_) => "6",
  }
}

fn tif_from_str(s :: Str) -> Option[TimeInForce] {
  if s == "0" {
    Some(Day(()))
  } else {
    if s == "1" {
      Some(Gtc(()))
    } else {
      if s == "3" {
        Some(Ioc(()))
      } else {
        if s == "4" {
          Some(Fok(()))
        } else {
          if s == "6" {
            Some(AtClose(()))
          } else {
            None
          }
        }
      }
    }
  }
}

# ---- ExecType (tag 150) ------------------------------------------
type ExecType = ExecNew(Unit) | ExecPartialFill(Unit) | ExecFill(Unit) | ExecCanceled(Unit) | ExecReplaced(Unit) | ExecRejected(Unit) | ExecPendingNew(Unit) | ExecPendingCancel(Unit)

fn exec_type_to_str(t :: ExecType) -> Str
  examples {
    exec_type_to_str(ExecNew(())) => "0",
    exec_type_to_str(ExecPartialFill(())) => "1",
    exec_type_to_str(ExecFill(())) => "2",
    exec_type_to_str(ExecRejected(())) => "8"
  }
{
  match t {
    ExecNew(_) => "0",
    ExecPartialFill(_) => "1",
    ExecFill(_) => "2",
    ExecCanceled(_) => "4",
    ExecReplaced(_) => "5",
    ExecRejected(_) => "8",
    ExecPendingNew(_) => "A",
    ExecPendingCancel(_) => "E",
  }
}

fn exec_type_from_str(s :: Str) -> Option[ExecType] {
  if s == "0" {
    Some(ExecNew(()))
  } else {
    if s == "1" {
      Some(ExecPartialFill(()))
    } else {
      if s == "2" {
        Some(ExecFill(()))
      } else {
        if s == "4" {
          Some(ExecCanceled(()))
        } else {
          if s == "5" {
            Some(ExecReplaced(()))
          } else {
            if s == "8" {
              Some(ExecRejected(()))
            } else {
              if s == "A" {
                Some(ExecPendingNew(()))
              } else {
                if s == "E" {
                  Some(ExecPendingCancel(()))
                } else {
                  None
                }
              }
            }
          }
        }
      }
    }
  }
}

# ---- OrdStatus (tag 39) ------------------------------------------
type OrdStatus = StatusNew(Unit) | StatusPartiallyFilled(Unit) | StatusFilled(Unit) | StatusCanceled(Unit) | StatusRejected(Unit) | StatusPendingNew(Unit)

fn ord_status_to_str(s :: OrdStatus) -> Str
  examples {
    ord_status_to_str(StatusNew(())) => "0",
    ord_status_to_str(StatusPartiallyFilled(())) => "1",
    ord_status_to_str(StatusFilled(())) => "2",
    ord_status_to_str(StatusCanceled(())) => "4"
  }
{
  match s {
    StatusNew(_) => "0",
    StatusPartiallyFilled(_) => "1",
    StatusFilled(_) => "2",
    StatusCanceled(_) => "4",
    StatusRejected(_) => "8",
    StatusPendingNew(_) => "A",
  }
}

fn ord_status_from_str(s :: Str) -> Option[OrdStatus] {
  if s == "0" {
    Some(StatusNew(()))
  } else {
    if s == "1" {
      Some(StatusPartiallyFilled(()))
    } else {
      if s == "2" {
        Some(StatusFilled(()))
      } else {
        if s == "4" {
          Some(StatusCanceled(()))
        } else {
          if s == "8" {
            Some(StatusRejected(()))
          } else {
            if s == "A" {
              Some(StatusPendingNew(()))
            } else {
              None
            }
          }
        }
      }
    }
  }
}

# ---- CxlRejReason (tag 102) -------------------------------------
type CxlRejReason = TooLateToCancel(Unit) | UnknownOrder(Unit) | BrokerOption(Unit) | AlreadyPendingCxlOrReplace(Unit)

fn cxl_rej_reason_to_str(r :: CxlRejReason) -> Str
  examples {
    cxl_rej_reason_to_str(TooLateToCancel(())) => "0",
    cxl_rej_reason_to_str(UnknownOrder(())) => "1",
    cxl_rej_reason_to_str(BrokerOption(())) => "2",
    cxl_rej_reason_to_str(AlreadyPendingCxlOrReplace(())) => "3"
  }
{
  match r {
    TooLateToCancel(_) => "0",
    UnknownOrder(_) => "1",
    BrokerOption(_) => "2",
    AlreadyPendingCxlOrReplace(_) => "3",
  }
}

fn cxl_rej_reason_from_str(s :: Str) -> Option[CxlRejReason] {
  if s == "0" {
    Some(TooLateToCancel(()))
  } else {
    if s == "1" {
      Some(UnknownOrder(()))
    } else {
      if s == "2" {
        Some(BrokerOption(()))
      } else {
        if s == "3" {
          Some(AlreadyPendingCxlOrReplace(()))
        } else {
          None
        }
      }
    }
  }
}

# ---- CxlRejResponseTo (tag 434) ---------------------------------
type CxlRejResponseTo = ResponseToCancel(Unit) | ResponseToReplace(Unit)

fn cxl_rej_response_to_to_str(r :: CxlRejResponseTo) -> Str
  examples {
    cxl_rej_response_to_to_str(ResponseToCancel(())) => "1",
    cxl_rej_response_to_to_str(ResponseToReplace(())) => "2"
  }
{
  match r {
    ResponseToCancel(_) => "1",
    ResponseToReplace(_) => "2",
  }
}

fn cxl_rej_response_to_from_str(s :: Str) -> Option[CxlRejResponseTo] {
  if s == "1" {
    Some(ResponseToCancel(()))
  } else {
    if s == "2" {
      Some(ResponseToReplace(()))
    } else {
      None
    }
  }
}

# ---- All-values catalogs for schema validation -------------------
fn all_sides() -> List[Str] {
  ["1", "2"]
}

fn all_ord_types() -> List[Str] {
  ["1", "2", "3", "4"]
}

fn all_time_in_forces() -> List[Str] {
  ["0", "1", "3", "4", "6"]
}

fn all_exec_types() -> List[Str] {
  ["0", "1", "2", "4", "5", "8", "A", "E"]
}

fn all_ord_statuses() -> List[Str] {
  ["0", "1", "2", "4", "8", "A"]
}

fn all_cxl_rej_reasons() -> List[Str] {
  ["0", "1", "2", "3"]
}

fn all_cxl_rej_response_tos() -> List[Str] {
  ["1", "2"]
}

