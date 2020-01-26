module Msg exposing (..)

import Browser exposing (UrlRequest)
import Http
import Url exposing (Url)
import Utils.Api exposing (ApiGameList, ApiRoot)

type Msg
    = ApiGameListRetrieved (Result Http.Error ApiGameList)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
    | RequestUrl UrlRequest
    | UrlChanged Url