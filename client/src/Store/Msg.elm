module Store.Msg exposing (Msg(..))

import Api.Model exposing (ApiGame, ApiGameList, ApiIdentity, ApiLocalAuthentication, ApiRoot, ApiUserWithToken)
import Browser exposing (UrlRequest)
import Http
import Pages.Login.Msg as LoginPage
import Pages.Register.Msg as RegisterPage
import Url exposing (Url)


type
    Msg
    -- API
    -- TODO: rename to OperationResourceResponseReceived (e.g. RetrieveApiGameResponseReceived)
    = ApiAuthenticatedLocally (Result Http.Error ApiLocalAuthentication)
    | ApiCreateLocalIdentityResponseReceived (Result Http.Error ApiIdentity)
    | ApiCreateUserResponseReceived (Result Http.Error ApiUserWithToken)
    | ApiGameRetrieved (Result Http.Error ApiGame)
    | ApiGameListRetrieved (Result Http.Error ApiGameList)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
      -- Authentication
    | LogOut
      -- Pages
    | LoginPage LoginPage.Msg
    | RegisterPage RegisterPage.Msg
      -- Navigation
    | RequestUrl UrlRequest
    | UrlChanged Url
