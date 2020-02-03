module Pages.Game.Model exposing (Model, ViewModel)

import Api.Model exposing (ApiBoard, ApiGame, ApiPlayer, ApiPossibleActionList)
import Store.Session exposing (AuthModel)
import Types exposing (RemoteData)


type alias Model =
    { board : RemoteData ApiBoard
    , gameId : RemoteData String
    , possibleActions : RemoteData ApiPossibleActionList
    }


type alias ViewModel =
    { auth : Maybe AuthModel
    , board : RemoteData ApiBoard
    , game : RemoteData ApiGame
    , joinable : Bool
    , players : List ApiPlayer
    , possibleActions : RemoteData ApiPossibleActionList
    }
