module Pages.Game.Model exposing (Model, ViewModel)

import Api.Model exposing (ApiGame, ApiPossibleActionList)
import Types exposing (RemoteData)


type alias Model =
    { gameId : RemoteData String
    , possibleActions : RemoteData ApiPossibleActionList
    }


type alias ViewModel =
    { game : RemoteData ApiGame
    , joinable : Bool
    , possibleActions : RemoteData ApiPossibleActionList
    }
