module Types exposing (RemoteData(..))

import Http


type RemoteData a
    = NotAsked
    | Loading
    | Loaded a
    | Refreshing a
    | Error Http.Error
