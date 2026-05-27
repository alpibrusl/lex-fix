# lex-fix — FixMessage type and builders
#
# A `FixMessage` is a flat ordered list of FixFields. The header
# fields (8, 9, 35, 49, 56, 34, 52) are conventionally first;
# the trailer checksum (10) is last. Structural accessors are
# provided for the most common header lookups.
#
# Effects: none.

import "std.list" as list
import "std.str"  as str

import "./field" as field
import "./tag"   as tag

type FixMessage = {
  fields :: List[field.FixField],
}

fn new(fields :: List[field.FixField]) -> FixMessage {
  { fields: fields }
}

fn empty() -> FixMessage { { fields: [] } }

fn msg_type(msg :: FixMessage) -> Option[Str] {
  field.get(msg.fields, tag.msg_type())
}

fn sender(msg :: FixMessage) -> Option[Str] {
  field.get(msg.fields, tag.sender_comp_id())
}

fn target(msg :: FixMessage) -> Option[Str] {
  field.get(msg.fields, tag.target_comp_id())
}

fn seq_num(msg :: FixMessage) -> Option[Str] {
  field.get(msg.fields, tag.msg_seq_num())
}

fn get(msg :: FixMessage, t :: Int) -> Option[Str] {
  field.get(msg.fields, t)
}

# Append additional fields to a message.
fn with_fields(msg :: FixMessage, extra :: List[field.FixField]) -> FixMessage {
  { fields: list.concat(msg.fields, extra) }
}

# Build a standard FIX 4.4 header block.
fn header(
  mt          :: Str,
  sender_id   :: Str,
  target_id   :: Str,
  seq_num_val :: Str,
  timestamp   :: Str
) -> List[field.FixField] {
  [
    { tag: tag.begin_string(),   value: "FIX.4.4" },
    { tag: tag.msg_type(),       value: mt },
    { tag: tag.sender_comp_id(), value: sender_id },
    { tag: tag.target_comp_id(), value: target_id },
    { tag: tag.msg_seq_num(),    value: seq_num_val },
    { tag: tag.sending_time(),   value: timestamp },
  ]
}

# Look up a specific body field.
fn body_field(msg :: FixMessage, t :: Int) -> Option[Str] {
  field.get(msg.fields, t)
}
