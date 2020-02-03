module Pages.Game.Msg exposing (Msg(..))

import Api.Model exposing (ApiBoard, ApiGame, ApiGameDetailed, ApiPlayer, ApiPossibleActionList)
import Http
import Store.Session exposing (AuthModel)
import Time


type Msg
    = ApiActionCreated
    | ApiBoardRetrieved (Result Http.Error ApiBoard)
    | ApiGamePageGameRetrieved (Result Http.Error ApiGameDetailed)
    | ApiGamePagePlayerCreated (Result Http.Error ApiPlayer)
    | ApiGamePagePossibleActionsRetrieved (Result Http.Error ApiPossibleActionList)
    | JoinGame ApiGame
    | Play AuthModel Int Int
    | RefreshGameState Time.Posix
    | RefreshOngoingGameState Time.Posix
