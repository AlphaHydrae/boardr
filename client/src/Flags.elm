module Flags exposing (Flags, ProgramFlags, defaultFlags, flagsDecoder)

import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline exposing (optional)
import Store.Session exposing (SessionModel, sessionDecoder)


type alias Flags =
    -- FIXME: apiUrl should be an Url
    { apiUrl : String
    , session : SessionModel
    }


type alias ProgramFlags =
    Decode.Value


defaultFlags : Flags
defaultFlags =
    { apiUrl = ""
    , session = Nothing
    }


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> optional "apiUrl" string ""
        |> optional "session" sessionDecoder Nothing
