# lex-fix — venue registry and per-venue FIX conformance profiles
#
# FIX 4.4 is a standard, but every exchange deviates: custom required
# tags, dialect versions, and order-type restrictions. A routing layer
# needs to know which extra rules apply per venue. This module is a
# pure registry; the venue-aware conformance check lives in
# conformance.lex (validate_new_order_venue), which runs base FIX 4.4
# conformance first and then layers the venue profile on top.
#
# Effects: none.

import "std.str" as str

type Venue = Nyse(Unit) | Nasdaq(Unit) | Lse(Unit) | Euronext(Unit) | Cboe(Unit) | Unknown(Str)

type VenueProfile = { venue :: Venue, fix_version :: Str, custom_tags :: List[Int], restrictions :: List[Str] }

fn venue_to_str(v :: Venue) -> Str {
  match v {
    Nyse(_) => "NYSE",
    Nasdaq(_) => "NASDAQ",
    Lse(_) => "LSE",
    Euronext(_) => "EURONEXT",
    Cboe(_) => "CBOE",
    Unknown(s) => s,
  }
}

# Resolve a venue from a name or MIC code; anything unrecognized maps
# to Unknown so the caller still gets base FIX 4.4 conformance.
fn venue_from_str(s :: Str) -> Venue {
  let u := str.to_upper(s)
  if u == "NYSE" or u == "XNYS" {
    Nyse(())
  } else {
    if u == "NASDAQ" or u == "XNAS" {
      Nasdaq(())
    } else {
      if u == "LSE" or u == "XLON" {
        Lse(())
      } else {
        if u == "EURONEXT" or u == "XPAR" {
          Euronext(())
        } else {
          if u == "CBOE" or u == "XCBO" or u == "BATS" {
            Cboe(())
          } else {
            Unknown(s)
          }
        }
      }
    }
  }
}

# The conformance profile for a venue. Profiles are deliberately
# conservative: only well-established deviations are encoded.
#
# NYSE eliminated stop orders (and GTC stop orders) in February 2016,
# so a Stop / StopLimit routed to NYSE is non-conformant.
fn venue_profile(v :: Venue) -> VenueProfile {
  match v {
    Nyse(_) => { venue: Nyse(()), fix_version: "FIX.4.4", custom_tags: [], restrictions: ["no_stop_orders"] },
    Nasdaq(_) => { venue: Nasdaq(()), fix_version: "FIX.4.4", custom_tags: [], restrictions: [] },
    Lse(_) => { venue: Lse(()), fix_version: "FIX.4.4", custom_tags: [], restrictions: [] },
    Euronext(_) => { venue: Euronext(()), fix_version: "FIX.4.4", custom_tags: [], restrictions: [] },
    Cboe(_) => { venue: Cboe(()), fix_version: "FIX.4.4", custom_tags: [], restrictions: [] },
    Unknown(s) => { venue: Unknown(s), fix_version: "FIX.4.4", custom_tags: [], restrictions: [] },
  }
}

