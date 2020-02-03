module Api.Req exposing (authenticateLocally, createGame, createLocalIdentity, createPlayer, createUser, retrieveBoard, retrieveGamePageGame, retrieveGamePossibleActions, retrieveHomePageGames, retrieveRoot)

import Api.Model exposing (ApiGame, ApiIdentity, ApiRoot, apiBoardDecoder, apiGameDetailedDecoder, apiGameListDecoder, apiIdentityDecoder, apiLocalAuthenticationDecoder, apiPlayerDecoder, apiPossibleActionListDecoder, apiRootDecoder, apiUserWithTokenDecoder)
import Dict
import Http exposing (header)
import Json.Encode as E
import Pages.Game.Msg exposing (Msg(..))
import Pages.Home.Msg exposing (Msg(..))
import Pages.Login.Model as LoginPage
import Pages.Register.Model as RegisterPage
import Store.Msg exposing (Msg(..))
import Store.Session exposing (AuthModel)
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


createPlayer : AuthModel -> ApiGame -> Cmd Msg
createPlayer auth apiGame =
    Http.request
        { method = "POST"
        , url = apiGame.playersLink.href
        , body = Http.jsonBody (E.object [])
        , headers = [ header "Authorization" ("Bearer " ++ auth.token) ]
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectJson (\d -> GamePage (ApiGamePagePlayerCreated d)) apiPlayerDecoder
        }


createGame : AuthModel -> ApiRoot -> Cmd Msg
createGame auth apiRoot =
    Http.request
        { method = "POST"
        , url = apiRoot.gamesLink.href ++ "?embed=boardr:players"
        , body = Http.jsonBody (E.object [ ( "rules", E.string "tic-tac-toe" ) ])
        , headers = [ header "Authorization" ("Bearer " ++ auth.token) ]
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectJson (\d -> HomePage (ApiHomePageGameCreated d)) apiGameDetailedDecoder
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


retrieveBoard : ApiGame -> Cmd Msg
retrieveBoard apiGame =
    Http.get
        { url = apiGame.boardLink.href
        , expect = Http.expectJson (\d -> GamePage (ApiBoardRetrieved d)) apiBoardDecoder
        }


retrieveRoot : String -> Cmd Msg
retrieveRoot apiUrl =
    Http.get
        { url = apiUrl
        , expect = Http.expectJson ApiRootRetrieved apiRootDecoder
        }


retrieveGamePageGame : String -> ApiRoot -> Cmd Msg
retrieveGamePageGame gameId apiRoot =
    Http.get
        { url = interpolate apiRoot.gameLink.href (Dict.fromList [ ( "id", gameId ) ]) ++ "?embed=boardr:players"
        , expect = Http.expectJson (\d -> GamePage (ApiGamePageGameRetrieved d)) apiGameDetailedDecoder
        }


retrieveGamePossibleActions : ApiGame -> Cmd Msg
retrieveGamePossibleActions game =
    Http.get
        { url = game.possibleActionsLink.href ++ "?embed=boardr:game"
        , expect = Http.expectJson (\d -> GamePage (ApiGamePagePossibleActionsRetrieved d)) apiPossibleActionListDecoder
        }


retrieveHomePageGames : ApiRoot -> Cmd Msg
retrieveHomePageGames apiRoot =
    Http.get
        { url = apiRoot.gamesLink.href ++ "?embed=boardr:players"
        , expect = Http.expectJson (\d -> HomePage (ApiHomePageGamesRetrieved d)) apiGameListDecoder
        }
