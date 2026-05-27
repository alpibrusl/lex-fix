# lex-fix — FIX tag number constants
#
# FIX Protocol: each field has a numeric tag. Using functions
# (rather than global constants) keeps the tag references
# typo-proof and greppable. All standard FIX 4.4 tags.
#
# Effects: none.

# ---- Standard header tags ----------------------------------------
fn begin_string()      -> Int { 8 }
fn body_length()       -> Int { 9 }
fn msg_type()          -> Int { 35 }
fn sender_comp_id()    -> Int { 49 }
fn target_comp_id()    -> Int { 56 }
fn msg_seq_num()       -> Int { 34 }
fn sending_time()      -> Int { 52 }
fn check_sum()         -> Int { 10 }

# ---- Message type values (tag 35) --------------------------------
fn mt_new_order_single()  -> Str { "D" }
fn mt_execution_report()  -> Str { "8" }
fn mt_heartbeat()         -> Str { "0" }
fn mt_logon()             -> Str { "A" }
fn mt_logout()            -> Str { "5" }
fn mt_order_cancel()         -> Str { "F" }
fn mt_order_cancel_replace() -> Str { "G" }
fn mt_order_status()         -> Str { "H" }
fn mt_order_cancel_reject()  -> Str { "9" }

# ---- Order / execution fields ------------------------------------
fn cl_ord_id()         -> Int { 11 }
fn order_id()          -> Int { 37 }
fn account()           -> Int { 1 }
fn symbol()            -> Int { 55 }
fn side()              -> Int { 54 }
fn transact_time()     -> Int { 60 }
fn order_qty()         -> Int { 38 }
fn ord_type()          -> Int { 40 }
fn price()             -> Int { 44 }
fn stop_px()           -> Int { 99 }
fn time_in_force()     -> Int { 59 }
fn security_exchange() -> Int { 207 }
fn exec_id()           -> Int { 17 }
fn exec_type()         -> Int { 150 }
fn ord_status()        -> Int { 39 }
fn cum_qty()           -> Int { 14 }
fn leaves_qty()        -> Int { 151 }
fn avg_px()            -> Int { 6 }
fn last_px()           -> Int { 31 }
fn last_qty()          -> Int { 32 }
fn text()              -> Int { 58 }
fn currency_tag()      -> Int { 15 }
fn on_behalf_of()         -> Int { 115 }
fn deliver_to()           -> Int { 128 }
fn orig_cl_ord_id()       -> Int { 41 }
fn cxl_rej_reason()       -> Int { 102 }
fn cxl_rej_response_to()  -> Int { 434 }
