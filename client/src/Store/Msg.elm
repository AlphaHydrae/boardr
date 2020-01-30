module Store.Msg exposing (Msg(..))

import Api.Model exposing (ApiGame, ApiGameList, ApiIdentity, ApiRoot, ApiUser)
import Browser exposing (UrlRequest)
import Http
import Url exposing (Url)


type
    Msg
    -- API
    -- TODO: rename to OperationResourceResponseReceived (e.g. RetrieveApiGameResponseReceived)
    = ApiCreateLocalIdentityResponseReceived (Result Http.Error ApiIdentity)
    | ApiCreateUserResponseReceived (Result Http.Error ApiUser)
    | ApiGameRetrieved (Result Http.Error ApiGame)
    | ApiGameListRetrieved (Result Http.Error ApiGameList)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
      -- Register form
    | EditRegisterEmail String
    | EditRegisterUsername String
    | SubmitRegisterForm
      -- Navigation
    | RequestUrl UrlRequest
    | UrlChanged Url
