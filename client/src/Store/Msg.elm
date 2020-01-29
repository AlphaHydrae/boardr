module Store.Msg exposing (Msg(..))

import Api exposing (ApiGame, ApiGameList, ApiIdentity, ApiRoot, ApiUser)
import Browser exposing (UrlRequest)
import Http
import Url exposing (Url)


type
    Msg
    -- API
    -- TODO: rename to OperationResourceResponseReceived (e.g. RetrieveApiGameResponseReceived)
    = ApiCreateIdentityResponseReceived (Result Http.Error ApiIdentity)
    | ApiCreateUserResponseReceived (Result Http.Error ApiUser)
    | ApiGameRetrieved (Result Http.Error ApiGame)
    | ApiGameListRetrieved (Result Http.Error ApiGameList)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
      -- Register form
    | EditRegisterEmail String
    | SubmitRegisterForm
      -- Navigation
    | RequestUrl UrlRequest
    | UrlChanged Url
