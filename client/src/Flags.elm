module Flags exposing (defaultFlags, Flags, flagsDecoder, ProgramFlags)

import Json.Decode as Decode exposing (field, map, maybe, string)

-- FIXME: apiUrl should be an Url
type alias ApiUrl = String

type alias Flags = ApiUrl


type alias ProgramFlags =
    Decode.Value


defaultFlags : Flags
defaultFlags = ""


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    field "apiUrl" (map apiUrlDecoder (maybe string))


apiUrlDecoder : Maybe String -> ApiUrl
apiUrlDecoder optionalApiUrl =
    case optionalApiUrl of
       Just apiUrl -> apiUrl
       _ -> ""