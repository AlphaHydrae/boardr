module Store.Msg exposing (Msg(..))

import Api.Model exposing (ApiIdentity, ApiLocalAuthentication, ApiRoot, ApiUserWithToken)
import Browser exposing (UrlRequest)
import Http
import Pages.Game.Msg as GamePage
import Pages.Home.Msg as HomePage
import Pages.Login.Msg as LoginPage
import Pages.Register.Msg as RegisterPage
import Time exposing (Zone)
import Url exposing (Url)


type
    Msg
    -- API
    -- TODO: rename to OperationResourceResponseReceived (e.g. RetrieveApiGameResponseReceived)
    = ApiAuthenticatedLocally (Result Http.Error ApiLocalAuthentication)
    | ApiLocalIdentityCreated (Result Http.Error ApiIdentity)
    | ApiRootRetrieved (Result Http.Error ApiRoot)
    | ApiUserCreated (Result Http.Error ApiUserWithToken)
      -- Pages
    | GamePage GamePage.Msg
    | HomePage HomePage.Msg
    | LoginPage LoginPage.Msg
    | RegisterPage RegisterPage.Msg
      -- Authentication
    | LogOut
      -- Navigation
    | RequestUrl UrlRequest
    | UrlChanged Url
      -- Other
    | TimeZoneRetrieved Zone
