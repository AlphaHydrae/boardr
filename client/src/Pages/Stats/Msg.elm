module Pages.Stats.Msg exposing (Msg(..))

import Api.Model exposing (ApiStats)
import Http
import Time


type Msg
    = ApiStatsRetrieved (Result Http.Error ApiStats)
    | RefreshApiStats Time.Posix
