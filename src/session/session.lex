# lex-fix — FIX session state machine
#
# The session layer manages the lifecycle of a logical connection to a
# counterparty: the logon handshake, steady-state heartbeating, and an
# orderly (or abrupt) logout. This module owns the *protocol* — a pure
# state machine over SessionState/SessionEvent. The actual TCP I/O
# lives in lex-web; lex-fix never opens a socket.
#
# Effects: none.

import "std.str" as str

type SessionState = Disconnected(Unit) | LoggingIn(Unit) | Active(Unit) | LoggingOut(Unit)

type SessionEvent = Connect(Unit) | LogonAck(Unit) | Heartbeat(Unit) | TestRequest(Unit) | Logout(Unit) | Disconnect(Unit)

fn state_name(s :: SessionState) -> Str {
  match s {
    Disconnected(_) => "Disconnected",
    LoggingIn(_) => "LoggingIn",
    Active(_) => "Active",
    LoggingOut(_) => "LoggingOut",
  }
}

fn event_name(ev :: SessionEvent) -> Str {
  match ev {
    Connect(_) => "Connect",
    LogonAck(_) => "LogonAck",
    Heartbeat(_) => "Heartbeat",
    TestRequest(_) => "TestRequest",
    Logout(_) => "Logout",
    Disconnect(_) => "Disconnect",
  }
}

# The state a fresh session starts in.
fn initial() -> SessionState {
  Disconnected(())
}

fn reject(state :: SessionState, event :: SessionEvent) -> Str {
  str.concat("invalid transition: ", str.concat(event_name(event), str.concat(" in state ", state_name(state))))
}

# Pure transition function for an initiator session.
#
#   Disconnected --Connect--> LoggingIn --LogonAck--> Active
#   Active --Heartbeat/TestRequest--> Active   (steady state)
#   Active --Logout--> LoggingOut --Logout--> Disconnected
#
# A Disconnect may arrive in any state (the transport can drop at any
# time) and always returns to Disconnected. Every other state/event
# pair that is not part of the protocol returns a descriptive Err.
fn session_transition(state :: SessionState, event :: SessionEvent) -> Result[SessionState, Str] {
  match event {
    Disconnect(_) => Ok(Disconnected(())),
    _ => match state {
      Disconnected(_) => match event {
        Connect(_) => Ok(LoggingIn(())),
        _ => Err(reject(state, event)),
      },
      LoggingIn(_) => match event {
        LogonAck(_) => Ok(Active(())),
        _ => Err(reject(state, event)),
      },
      Active(_) => match event {
        Heartbeat(_) => Ok(Active(())),
        TestRequest(_) => Ok(Active(())),
        Logout(_) => Ok(LoggingOut(())),
        _ => Err(reject(state, event)),
      },
      LoggingOut(_) => match event {
        Logout(_) => Ok(Disconnected(())),
        _ => Err(reject(state, event)),
      },
    },
  }
}

