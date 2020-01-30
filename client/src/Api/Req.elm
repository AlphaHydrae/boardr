module Api.Req exposing (authenticateLocally, createLocalIdentity, createUser, retrieveGame, retrieveGameList, retrieveRoot)

import Api.Model exposing (ApiIdentity, ApiRoot, apiGameDecoder, apiGameListDecoder, apiIdentityDecoder, apiLocalAuthenticationDecoder, apiRootDecoder, apiUserWithTokenDecoder)
import Dict
import Http exposing (header)
import Json.Encode as E
import Pages.Login.Model as LoginPage
import Pages.Register.Model as RegisterPage
import Store.Msg exposing (Msg(..))
import Url.Interpolate exposing (interpolate)


authenticateLocally : LoginPage.Model -> ApiRoot -> Cmd Msg
authenticateLocally model apiRoot =
    Http.post
        { url = apiRoot.localAuthLink.href
        , body = Http.jsonBody (E.object [ ( "email", E.string model ) ])
        , expect = Http.expectJson ApiAuthenticatedLocally apiLocalAuthenticationDecoder
        }


createLocalIdentity : RegisterPage.Model -> ApiRoot -> Cmd Msg
createLocalIdentity model apiRoot =
    Http.post
        { url = apiRoot.identitiesLink.href
        , body = Http.jsonBody (E.object [ ( "email", E.string model.email ), ( "provider", E.string "local" ) ])
        , expect = Http.expectJson ApiLocalIdentityCreated apiIdentityDecoder
        }


createUser : String -> ApiIdentity -> ApiRoot -> Cmd Msg
createUser name apiIdentity apiRoot =
    Http.request
        { method = "POST"
        , url = apiRoot.usersLink.href
        , body = Http.jsonBody (E.object [ ( "name", E.string name ) ])
        , headers = [ header "Authorization" ("Bearer " ++ apiIdentity.token) ]
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectJson ApiUserCreated apiUserWithTokenDecoder
        }


retrieveRoot : String -> Cmd Msg
retrieveRoot apiUrl =
    Http.get
        { url = apiUrl
        , expect = Http.expectJson ApiRootRetrieved apiRootDecoder
        }


retrieveGame : String -> ApiRoot -> Cmd Msg
retrieveGame gameId apiRoot =
    Http.get
        { url = interpolate apiRoot.gameLink.href (Dict.fromList [ ( "{id}", gameId ) ])
        , expect = Http.expectJson ApiGameRetrieved apiGameDecoder
        }


retrieveGameList : ApiRoot -> Cmd Msg
retrieveGameList apiRoot =
    Http.get
        { url = apiRoot.gamesLink.href ++ "?embed=boardr:players"
        , expect = Http.expectJson ApiGameListRetrieved apiGameListDecoder
        }
