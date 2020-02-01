module Types exposing (RemoteData(..))

import Http


type RemoteData a
    = Loading
    | Loaded a
    | Refreshing a
    | Error Http.Error
