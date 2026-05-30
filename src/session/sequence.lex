# lex-fix — FIX sequence number tracking
#
# Every FIX message carries MsgSeqNum (34). Each side maintains an
# outbound counter (the next number to send) and an expected inbound
# counter (the next number it expects to receive). A higher-than-
# expected inbound number is a gap and triggers a ResendRequest; a
# lower-than-expected number is unrecoverable.
#
# `next_seq` is pure: it returns the number to stamp on the next
# outbound message together with the advanced store. Persisting the
# store across a real connection is the caller's job (lex-web), which
# is where the [io] edge lives — this module stays pure and testable.
#
# Effects: none.

import "../error" as e

type SeqStore = { outbound :: Int, inbound :: Int }

# Result of advancing the outbound counter. Records — not bare tuples —
# are the house style throughout lex-fix.
type NextSeq = { seq :: Int, store :: SeqStore }

# FIX sequence numbers start at 1 on a fresh session.
fn new_store() -> SeqStore {
  { outbound: 1, inbound: 1 }
}

fn with_seqs(outbound :: Int, inbound :: Int) -> SeqStore {
  { outbound: outbound, inbound: inbound }
}

# Return the next outbound sequence number and the advanced store.
fn next_seq(store :: SeqStore) -> NextSeq {
  { seq: store.outbound, store: { outbound: store.outbound + 1, inbound: store.inbound } }
}

# Record that an in-order inbound message numbered `seq` was processed:
# the next expected inbound becomes seq + 1.
fn record_inbound(store :: SeqStore, seq :: Int) -> SeqStore {
  { outbound: store.outbound, inbound: seq + 1 }
}

# ResetSeqNumFlag=Y / a SequenceReset to 1: both counters return to 1.
fn reset() -> SeqStore {
  new_store()
}

# Validate an inbound MsgSeqNum against the expected value.
# - got == expected : Ok
# - got >  expected : gap — caller should send a ResendRequest
# - got <  expected : too low — unrecoverable, caller should logout
fn validate_incoming_seq(expected :: Int, got :: Int) -> Result[Unit, e.FixError] {
  if got == expected {
    Ok(())
  } else {
    if got > expected {
      Err(SequenceGap(expected, got))
    } else {
      Err(SequenceTooLow(expected, got))
    }
  }
}

# True when an inbound sequence number indicates a recoverable gap
# (i.e. validate_incoming_seq returned SequenceGap). Lets a caller
# decide to issue a ResendRequest without re-matching the error.
fn is_gap(expected :: Int, got :: Int) -> Bool {
  got > expected
}

