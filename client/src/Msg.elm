module Msg exposing (..)

import Browser exposing (UrlRequest)
import Http
import Url exposing (Url)
import Utils.Api exposing (ApiGameList)

type Msg
    = ApiGameListRetrieved (Result Http.Error ApiGameList)
    | RequestUrl UrlRequest
    | UrlChanged Url