module Pages.Home.Model exposing (Model, ViewModel)

import Api.Model exposing (ApiGame, ApiUser)
import Types exposing (RemoteData)


type alias Model = RemoteData (List String)


type alias ViewModel =
    { currentUser : Maybe ApiUser
    , displayedGames : RemoteData (List ApiGame)
    }
