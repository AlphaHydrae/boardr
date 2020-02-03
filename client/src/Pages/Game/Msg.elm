module Pages.Game.Msg exposing (Msg(..))

import Api.Model exposing (ApiBoard, ApiGame, ApiGameDetailed, ApiPlayer, ApiPossibleActionList)
import Http
import Time


type Msg
    = ApiBoardRetrieved (Result Http.Error ApiBoard)
    | ApiGamePageGameRetrieved (Result Http.Error ApiGameDetailed)
    | ApiGamePagePlayerCreated (Result Http.Error ApiPlayer)
    | ApiGamePagePossibleActionsRetrieved (Result Http.Error ApiPossibleActionList)
    | JoinGame ApiGame
    | RefreshGameState Time.Posix
    | RefreshOngoingGameState Time.Posix
