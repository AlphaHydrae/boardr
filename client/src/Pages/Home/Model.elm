module Pages.Home.Model exposing (Model, ViewModel)

import Api.Model exposing (ApiGame, ApiUser)


type alias Model =
    List String


type alias ViewModel =
    { currentUser : Maybe ApiUser
    , displayedGames : List ApiGame
    }
