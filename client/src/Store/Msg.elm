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
    | ApiGameRetrieved (Result Http.Error ApiGame)
    | ApiGameListRetrieved (Result Http.Error ApiGameList)
    | ApiLocalIdentityCreated (Result Http.Error ApiIdentity)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
    | ApiUserCreated (Result Http.Error ApiUserWithToken)
      -- Authentication
    | LogOut
      -- Pages
    | LoginPage LoginPage.Msg
    | RegisterPage RegisterPage.Msg
      -- Navigation
    | RequestUrl UrlRequest
    | UrlChanged Url
