module Pages.Game.Msg exposing (Msg(..))

import Api.Model exposing (ApiGame, ApiGameDetailed, ApiPlayer, ApiPossibleActionList)
import Http
import Time


type Msg
    = ApiGamePageGameRetrieved (Result Http.Error ApiGameDetailed)
    | ApiGamePagePlayerCreated (Result Http.Error ApiPlayer)
    | ApiGamePagePossibleActionsRetrieved (Result Http.Error ApiPossibleActionList)
    | JoinGame ApiGame
    | RefreshGamePossibleActions Time.Posix
    | RefreshGameState Time.Posix
