module Store.Msg exposing (Msg (..))

import Api exposing (ApiGame, ApiGameList, ApiRoot)
import Browser exposing (UrlRequest)
import Http
import Url exposing (Url)

type Msg
    = ApiGameRetrieved (Result Http.Error ApiGame)
    | ApiGameListRetrieved (Result Http.Error ApiGameList)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
    | RequestUrl UrlRequest
    | UrlChanged Url