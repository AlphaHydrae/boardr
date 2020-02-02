module Pages.Game.Msg exposing (Msg(..))

import Api.Model exposing (ApiGame, ApiPossibleActionList)
import Http
import Time


type Msg
    = ApiGamePageGameRetrieved (Result Http.Error ApiGame)
    | ApiGamePagePossibleActionsRetrieved (Result Http.Error ApiPossibleActionList)
    | RefreshGamePossibleActions Time.Posix
    | RefreshGameState Time.Posix
