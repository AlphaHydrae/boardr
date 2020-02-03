module Pages.Game.Model exposing (Model, ViewModel)

import Api.Model exposing (ApiBoard, ApiGame, ApiPossibleActionList)
import Types exposing (RemoteData)


type alias Model =
    { board : RemoteData ApiBoard
    , gameId : RemoteData String
    , possibleActions : RemoteData ApiPossibleActionList
    }


type alias ViewModel =
    { board : RemoteData ApiBoard
    , game : RemoteData ApiGame
    , joinable : Bool
    , possibleActions : RemoteData ApiPossibleActionList
    }
