module Pages.Game.Msg exposing (Msg(..))

import Api.Model exposing (ApiGame)
import Http
import Time


type Msg
    = ApiGamePageGameRetrieved (Result Http.Error ApiGame)
    | RefreshGameState Time.Posix
