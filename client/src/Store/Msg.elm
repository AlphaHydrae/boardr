module Store.Msg exposing (Msg(..))

import Api.Model exposing (ApiGame, ApiGameList, ApiIdentity, ApiLocalAuthentication, ApiRoot, ApiUserWithToken)
import Browser exposing (UrlRequest)
import Http
import Pages.Home.Msg as HomePage
import Pages.Login.Msg as LoginPage
import Pages.Register.Msg as RegisterPage
import Url exposing (Url)


type
    Msg
    -- API
    -- TODO: rename to OperationResourceResponseReceived (e.g. RetrieveApiGameResponseReceived)
    = ApiAuthenticatedLocally (Result Http.Error ApiLocalAuthentication)
    | ApiGameRetrieved (Result Http.Error ApiGame)
    | ApiLocalIdentityCreated (Result Http.Error ApiIdentity)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
    | ApiUserCreated (Result Http.Error ApiUserWithToken)
      -- Pages
    | HomePage HomePage.Msg
    | LoginPage LoginPage.Msg
    | RegisterPage RegisterPage.Msg
      -- Navigation
    | RequestUrl UrlRequest
    | UrlChanged Url
