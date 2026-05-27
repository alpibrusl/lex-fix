# lex-fix — FIX 4.4 strongly-typed enum ADTs
#
# The FIX protocol uses single-character or short-string codes for
# enumerated fields. This module replaces stringly-typed field values
# with ADTs. Every variant maps to exactly one wire string; the
# from_str functions return Option so callers can handle unknown values.
#
# Effects: none.

# ---- Side (tag 54) -----------------------------------------------

type Side = Buy | Sell

fn side_to_str(s :: Side) -> Str
  examples {
    side_to_str(Buy)  => "1",
    side_to_str(Sell) => "2",
  }
{
  match s {
    Buy  => "1",
    Sell => "2",
  }
}

fn side_from_str(s :: Str) -> Option[Side] {
  if s == "1" { Some(Buy) }
  else if s == "2" { Some(Sell) }
  else { None }
}

# ---- OrdType (tag 40) --------------------------------------------

type OrdType = Market | Limit | Stop | StopLimit

fn ord_type_to_str(t :: OrdType) -> Str
  examples {
    ord_type_to_str(Market)    => "1",
    ord_type_to_str(Limit)     => "2",
    ord_type_to_str(Stop)      => "3",
    ord_type_to_str(StopLimit) => "4",
  }
{
  match t {
    Market    => "1",
    Limit     => "2",
    Stop      => "3",
    StopLimit => "4",
  }
}

fn ord_type_from_str(s :: Str) -> Option[OrdType] {
  if s == "1" { Some(Market) }
  else if s == "2" { Some(Limit) }
  else if s == "3" { Some(Stop) }
  else if s == "4" { Some(StopLimit) }
  else { None }
}

fn ord_type_requires_price(t :: OrdType) -> Bool {
  match t {
    Limit     => True,
    StopLimit => True,
    Market    => False,
    Stop      => False,
  }
}

# ---- TimeInForce (tag 59) ----------------------------------------

type TimeInForce =
    Day
  | Gtc
  | Ioc
  | Fok
  | AtClose

fn tif_to_str(t :: TimeInForce) -> Str
  examples {
    tif_to_str(Day) => "0",
    tif_to_str(Gtc) => "1",
    tif_to_str(Ioc) => "3",
    tif_to_str(Fok) => "4",
  }
{
  match t {
    Day     => "0",
    Gtc     => "1",
    Ioc     => "3",
    Fok     => "4",
    AtClose => "6",
  }
}

fn tif_from_str(s :: Str) -> Option[TimeInForce] {
  if s == "0" { Some(Day) }
  else if s == "1" { Some(Gtc) }
  else if s == "3" { Some(Ioc) }
  else if s == "4" { Some(Fok) }
  else if s == "6" { Some(AtClose) }
  else { None }
}

# ---- ExecType (tag 150) ------------------------------------------

type ExecType =
    ExecNew
  | ExecPartialFill
  | ExecFill
  | ExecCanceled
  | ExecReplaced
  | ExecRejected
  | ExecPendingNew
  | ExecPendingCancel

fn exec_type_to_str(t :: ExecType) -> Str
  examples {
    exec_type_to_str(ExecNew)         => "0",
    exec_type_to_str(ExecPartialFill) => "1",
    exec_type_to_str(ExecFill)        => "2",
    exec_type_to_str(ExecRejected)    => "8",
  }
{
  match t {
    ExecNew          => "0",
    ExecPartialFill  => "1",
    ExecFill         => "2",
    ExecCanceled     => "4",
    ExecReplaced     => "5",
    ExecRejected     => "8",
    ExecPendingNew   => "A",
    ExecPendingCancel => "E",
  }
}

fn exec_type_from_str(s :: Str) -> Option[ExecType] {
  if s == "0" { Some(ExecNew) }
  else if s == "1" { Some(ExecPartialFill) }
  else if s == "2" { Some(ExecFill) }
  else if s == "4" { Some(ExecCanceled) }
  else if s == "5" { Some(ExecReplaced) }
  else if s == "8" { Some(ExecRejected) }
  else if s == "A" { Some(ExecPendingNew) }
  else if s == "E" { Some(ExecPendingCancel) }
  else { None }
}

# ---- OrdStatus (tag 39) ------------------------------------------

type OrdStatus =
    StatusNew
  | StatusPartiallyFilled
  | StatusFilled
  | StatusCanceled
  | StatusRejected
  | StatusPendingNew

fn ord_status_to_str(s :: OrdStatus) -> Str
  examples {
    ord_status_to_str(StatusNew)             => "0",
    ord_status_to_str(StatusPartiallyFilled) => "1",
    ord_status_to_str(StatusFilled)          => "2",
    ord_status_to_str(StatusCanceled)        => "4",
  }
{
  match s {
    StatusNew             => "0",
    StatusPartiallyFilled => "1",
    StatusFilled          => "2",
    StatusCanceled        => "4",
    StatusRejected        => "8",
    StatusPendingNew      => "A",
  }
}

fn ord_status_from_str(s :: Str) -> Option[OrdStatus] {
  if s == "0" { Some(StatusNew) }
  else if s == "1" { Some(StatusPartiallyFilled) }
  else if s == "2" { Some(StatusFilled) }
  else if s == "4" { Some(StatusCanceled) }
  else if s == "8" { Some(StatusRejected) }
  else if s == "A" { Some(StatusPendingNew) }
  else { None }
}

# ---- All-values catalogs for schema validation -------------------

fn all_sides()          -> List[Str] { ["1", "2"] }
fn all_ord_types()      -> List[Str] { ["1", "2", "3", "4"] }
fn all_time_in_forces() -> List[Str] { ["0", "1", "3", "4", "6"] }
fn all_exec_types()     -> List[Str] { ["0", "1", "2", "4", "5", "8", "A", "E"] }
fn all_ord_statuses()   -> List[Str] { ["0", "1", "2", "4", "8", "A"] }
