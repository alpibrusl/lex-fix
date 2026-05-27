# lex-fix — FixField type and list operations
#
# FIX messages are sequences of tag=value pairs. This module
# provides the `FixField` type and pure helpers that treat
# a `List[FixField]` as the canonical in-memory representation
# of a FIX message body.
#
# Effects: none.

import "std.list" as list

import "./error" as e

type FixField = {
  tag   :: Int,
  value :: Str,
}

fn field(tag :: Int, value :: Str) -> FixField {
  { tag: tag, value: value }
}

# Find the first field with the given tag, returning its value.
fn get(fields :: List[FixField], t :: Int) -> Option[Str]
  examples {
    get([{ tag: 35, value: "D" }, { tag: 55, value: "MSFT" }], 35) => Some("D"),
    get([{ tag: 35, value: "D" }], 99) => None,
  }
{
  list.fold(fields, None,
    fn (acc :: Option[Str], f :: FixField) -> Option[Str] {
      match acc {
        Some(_) => acc,
        None    => if f.tag == t { Some(f.value) } else { None },
      }
    })
}

# Like `get`, but returns Err(MissingRequiredTag) instead of None.
fn require(fields :: List[FixField], t :: Int) -> Result[Str, e.FixError] {
  match get(fields, t) {
    Some(v) => Ok(v),
    None    => Err(MissingRequiredTag(t)),
  }
}

fn has(fields :: List[FixField], t :: Int) -> Bool {
  match get(fields, t) {
    Some(_) => true,
    None    => false,
  }
}

# Return all fields except the one with the given tag, then append
# a new field with that tag.
fn set(fields :: List[FixField], t :: Int, v :: Str) -> List[FixField] {
  let rest := list.fold(fields, [],
    fn (acc :: List[FixField], f :: FixField) -> List[FixField] {
      if f.tag != t { list.concat(acc, [f]) } else { acc }
    })
  list.concat(rest, [{ tag: t, value: v }])
}

# Collect all error messages for tags that are present but do not
# match one of the allowed values.
fn validate_one_of(
  fields   :: List[FixField],
  t        :: Int,
  allowed  :: List[Str]
) -> Option[e.FixError] {
  match get(fields, t) {
    None    => None,
    Some(v) => {
      let found := list.fold(allowed, false,
        fn (acc :: Bool, a :: Str) -> Bool { if acc { true } else { v == a } })
      if found { None } else { Some(InvalidTagValue(t, v)) }
    },
  }
}
