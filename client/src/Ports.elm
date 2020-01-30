port module Ports exposing(saveSession)

import Json.Encode as E

port saveSession : E.Value -> Cmd msg
