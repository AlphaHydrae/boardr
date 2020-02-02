module Pages.Game.Msg exposing (Msg(..))

import Api.Model exposing (ApiGameDetailed, ApiPossibleActionList)
import Http
import Time


type Msg
    = ApiGamePageGameRetrieved (Result Http.Error ApiGameDetailed)
    | ApiGamePagePossibleActionsRetrieved (Result Http.Error ApiPossibleActionList)
    | RefreshGamePossibleActions Time.Posix
    | RefreshGameState Time.Posix
