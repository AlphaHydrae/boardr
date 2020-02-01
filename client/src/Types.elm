module Types exposing (RemoteData(..))

import Http


type RemoteData a
    = Loading
    | Loaded (a)
    | Error Http.Error
