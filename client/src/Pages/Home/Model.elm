module Pages.Home.Model exposing (Model, ViewModel)

import Utils.Api exposing (ApiGame)


type alias Model =
    { displayedGameIds : List String }


type alias ViewModel =
    { displayedGames : List ApiGame }
