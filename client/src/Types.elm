module Types exposing (RemoteData(..), getRemoteData)

import Http


type RemoteData a
    = NotAsked
    | Loading
    | Loaded a
    | Refreshing a
    | Error Http.Error


getRemoteData : RemoteData a -> Maybe a
getRemoteData data =
    case data of
        Loaded a ->
            Just a

        Refreshing a ->
            Just a

        Loading ->
            Nothing

        NotAsked ->
            Nothing

        Error _ ->
            Nothing
