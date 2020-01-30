module Api.Req exposing (createLocalIdentity, createUser, retrieveGame, retrieveGameList)

import Api exposing (ApiIdentity, ApiRoot, apiGameDecoder, apiGameListDecoder, apiIdentityDecoder, apiUserDecoder)
import Dict
import Http exposing (header)
import Json.Encode as E
import Pages.Register.Model as RegisterPage
import Store.Msg exposing (Msg(..))
import Url.Interpolate exposing (interpolate)


createLocalIdentity : RegisterPage.Model -> ApiRoot -> Cmd Msg
createLocalIdentity model apiRoot =
    Http.post
        { url = apiRoot.identitiesLink.href
        , body = Http.jsonBody (E.object [ ( "email", E.string model.email ), ( "provider", E.string "local" ) ])
        , expect = Http.expectJson ApiCreateLocalIdentityResponseReceived apiIdentityDecoder
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
        , expect = Http.expectJson ApiCreateUserResponseReceived apiUserDecoder
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
