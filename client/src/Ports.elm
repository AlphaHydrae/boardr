port module Ports exposing (saveSession)

import Json.Encode as Encode


port saveSession : Encode.Value -> Cmd msg
