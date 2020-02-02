module Pages.Game.Model exposing (Model, ViewModel)

import Api.Model exposing (ApiGame)
import Types exposing (RemoteData)


type alias Model = RemoteData String


type alias ViewModel = RemoteData ApiGame
