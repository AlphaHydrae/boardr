module Flags exposing (defaultFlags, Flags, flagsDecoder, ProgramFlags)

import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline exposing (optional)


type alias Flags =
    -- FIXME: apiUrl should be an Url
    { apiUrl : String }


type alias ProgramFlags =
    Decode.Value


defaultFlags =
    Flags ""


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> optional "apiUrl" string ""