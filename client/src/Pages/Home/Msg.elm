module Pages.Home.Msg exposing (Msg(..))

import Api.Model exposing (ApiGameDetailed, ApiGameList)
import Http
import Time


type Msg
    = ApiHomePageGameCreated (Result Http.Error ApiGameDetailed)
    | ApiHomePageGamesRetrieved (Result Http.Error ApiGameList)
    | CreateGame
    | LogOut
    | RefreshDisplayedGames Time.Posix
