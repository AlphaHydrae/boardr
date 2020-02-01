module Pages.Home.Msg exposing (Msg(..))

import Api.Model exposing (ApiGameList)
import Http
import Time


type Msg
    = ApiHomePageGamesRetrieved (Result Http.Error ApiGameList)
    | LogOut
    | RefreshDisplayedGames Time.Posix
