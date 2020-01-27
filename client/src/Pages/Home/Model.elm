module Pages.Home.Model exposing (Model, ViewModel)

import Api exposing (ApiGame)


type alias Model =
    List String


type alias ViewModel =
    List ApiGame
