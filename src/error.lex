# lex-fix — error ADT
#
# All failure modes are typed. Callers match on the variant to
# decide how to surface the failure (log, reject, alert).
#
# Effects: none.

import "std.str" as str

import "std.int" as int

type FixError = MissingRequiredTag(Int) | InvalidTagValue((Int, Str)) | UnsupportedMsgType(Str) | ConformanceViolation(Str) | ParseError(Str)

fn describe(e :: FixError) -> Str {
  match e {
    MissingRequiredTag(t) => str.concat("missing required tag ", int.to_str(t)),
    InvalidTagValue(t, v) => str.concat("invalid value ", str.concat(v, str.concat(" for tag ", int.to_str(t)))),
    UnsupportedMsgType(mt) => str.concat("unsupported MsgType: ", mt),
    ConformanceViolation(msg) => str.concat("conformance violation: ", msg),
    ParseError(msg) => str.concat("parse error: ", msg),
  }
}

