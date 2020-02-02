module Store.Update exposing (update)

import Api.Model exposing (ApiGame, ApiGameDetailed, ApiGameList, ApiIdentity, ApiLocalAuthentication, ApiRoot, ApiUserWithToken, apiGameWithoutDetails, apiUserWithoutToken)
import Api.Req exposing (authenticateLocally, createLocalIdentity, createUser, retrieveGamePageGame, retrieveGamePossibleActions, retrieveHomePageGames)
import Browser
import Browser.Navigation as Nav
import Dict
import Http
import Pages.Game.Msg exposing (Msg(..))
import Pages.Game.Page as GamePage
import Pages.Home.Msg exposing (Msg(..))
import Pages.Home.Page as HomePage
import Pages.Login.Msg exposing (Msg(..))
import Pages.Login.Page as LoginPage
import Pages.Register.Msg exposing (Msg(..))
import Pages.Register.Page as RegisterPage
import Platform.Cmd exposing (Cmd)
import Ports exposing (saveSession)
import Routes exposing (Route(..), toRoute)
import Store.Model exposing (DataModel, LocationModel, Model, UiModel)
import Store.Msg exposing (Msg(..))
import Store.Session exposing (AuthModel, SessionModel, sessionEncoder)
import Url exposing (Url)
import Url.Builder


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiAuthenticatedLocally res ->
            case res of
                Ok localAuth ->
                    let
                        newSession =
                            localAuth |> storeLocalAuthentication model.session
                    in
                    ( newSession |> storeSession model
                    , Cmd.batch
                        [ Nav.pushUrl model.location.key (Url.Builder.absolute [] [])
                        , saveSession (sessionEncoder newSession)
                        ]
                    )

                -- FIXME: handle ApiAuthenticatedLocally Err
                Err _ ->
                    ( model, Cmd.none )

        ApiLocalIdentityCreated res ->
            case ( res, model.data.root ) of
                ( Ok apiIdentity, Just apiRoot ) ->
                    ( apiIdentity
                        |> storeApiIdentity model.data
                        |> storeData model
                    , createUser model.ui.register.name apiIdentity apiRoot
                    )

                ( Ok apiIdentity, Nothing ) ->
                    ( apiIdentity
                        |> storeApiIdentity model.data
                        |> storeData model
                    , Cmd.none
                    )

                -- FIXME: handle ApiLocalIdentityCreated Err
                ( Err _, _ ) ->
                    ( model, Cmd.none )

        ApiRootRetrieved res ->
            case res of
                Ok apiRoot ->
                    let
                        -- Store API root data (HAL links).
                        newModel =
                            apiRoot
                                |> storeApiRoot model.data
                                |> storeData model
                    in
                    case model.location.route of
                        -- Retrieve the game list from the API on the home page.
                        HomeRoute ->
                            ( newModel, retrieveHomePageGames apiRoot )

                        -- Retrieve the current game from the API on the game page.
                        GameRoute id ->
                            ( newModel, retrieveGamePageGame id apiRoot )

                        _ ->
                            ( newModel, Cmd.none )

                -- FIXME: handle ApiRootRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

        ApiUserCreated res ->
            case res of
                Ok apiUserWithToken ->
                    let
                        newSession =
                            apiUserWithToken |> storeCreatedUser model.session
                    in
                    ( newSession |> storeSession model
                    , Cmd.batch
                        [ Nav.pushUrl model.location.key (Url.Builder.absolute [] [])
                        , saveSession (sessionEncoder newSession)
                        ]
                    )

                -- FIXME: handle ApiUserCreated Err
                Err _ ->
                    ( model, Cmd.none )

        GamePage sub ->
            ( case sub of
                ApiGamePageGameRetrieved res ->
                    case res of
                        -- Store game data from the API.
                        Ok apiGame ->
                            { model
                                | data = apiGame |> storeApiGame model.data
                                , ui = sub |> GamePage.updateUi model.ui
                            }

                        -- FIXME: handle ApiGamePageGameRetrieved Err
                        Err _ ->
                            model

                ApiGamePagePossibleActionsRetrieved _ ->
                    model

                RefreshGamePossibleActions _ ->
                    model

                RefreshGameState _ ->
                    model
            , case ( sub, model.location.route, model.data.root ) of
                ( RefreshGameState _, GameRoute id, Just apiRoot ) ->
                    retrieveGamePageGame id apiRoot

                ( RefreshGamePossibleActions _, GameRoute id, _ ) ->
                    case Dict.get id model.data.games of
                        Just apiGame ->
                            retrieveGamePossibleActions apiGame

                        _ ->
                            Cmd.none

                _ ->
                    Cmd.none
            )

        HomePage sub ->
            ( case sub of
                ApiHomePageGamesRetrieved res ->
                    { model
                        | data = res |> storeApiHomePageGames model.data
                        , ui = sub |> HomePage.updateUi model.ui
                    }

                LogOut ->
                    { model
                        | session = forgetAuth model.session
                        , ui = LogOut |> HomePage.updateUi model.ui
                    }

                _ ->
                    sub |> HomePage.updateUi model.ui |> storeUi model
            , case ( sub, model.data.root ) of
                ( LogOut, _ ) ->
                    saveSession (sessionEncoder (forgetAuth model.session))

                ( RefreshDisplayedGames _, Just apiRoot ) ->
                    retrieveHomePageGames apiRoot

                _ ->
                    Cmd.none
            )

        LoginPage sub ->
            ( sub |> LoginPage.store model.ui |> storeUi model
            , case ( sub, model.data.root ) of
                ( SubmitLoginForm, Just apiRoot ) ->
                    authenticateLocally model.ui.login apiRoot

                _ ->
                    Cmd.none
            )

        RegisterPage sub ->
            ( sub |> RegisterPage.store model.ui |> storeUi model
            , case ( sub, model.data.root ) of
                ( SubmitRegisterForm, Just apiRoot ) ->
                    createLocalIdentity model.ui.register apiRoot

                _ ->
                    Cmd.none
            )

        RequestUrl urlRequest ->
            case urlRequest of
                -- Request an update of the current location.
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.location.key (Url.toString url) )

                -- Go to an external page.
                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                route =
                    toRoute url
            in
            -- Update the current location.
            ( { model | location = updateLocation url route model.location }
            , case model.data.root of
                Just root ->
                    case route of
                        -- Retrieve the game list from the API when returning to the home page.
                        HomeRoute ->
                            retrieveHomePageGames root

                        _ ->
                            Cmd.none

                Nothing ->
                    Cmd.none
            )


forgetAuth : SessionModel -> SessionModel
forgetAuth _ =
    Nothing


storeApiGame : DataModel -> ApiGameDetailed -> DataModel
storeApiGame data apiGame =
    { data
      | games = Dict.insert apiGame.id (apiGameWithoutDetails apiGame) data.games
      , players = List.foldl (\p d -> Dict.insert p.id p d) data.players apiGame.players
    }


storeApiHomePageGames : DataModel -> Result Http.Error ApiGameList -> DataModel
storeApiHomePageGames data res =
    case res of
        Ok apiGameList ->
            { data
              | games = List.foldl (\g d -> Dict.insert g.id g d) data.games apiGameList.games
              , players = List.foldl (\p d -> Dict.insert p.id p d) data.players apiGameList.players
            }

        Err _ ->
            data


storeApiIdentity : DataModel -> ApiIdentity -> DataModel
storeApiIdentity data apiIdentity =
    { data | identities = Dict.insert apiIdentity.id apiIdentity data.identities }


storeApiRoot : DataModel -> ApiRoot -> DataModel
storeApiRoot data apiRoot =
    { data | root = Just apiRoot }


storeCreatedUser : SessionModel -> ApiUserWithToken -> SessionModel
storeCreatedUser _ apiUser =
    Just (AuthModel apiUser.token (apiUserWithoutToken apiUser))


storeData : Model -> DataModel -> Model
storeData model data =
    { model | data = data }


storeLocalAuthentication : SessionModel -> ApiLocalAuthentication -> SessionModel
storeLocalAuthentication _ localAuth =
    Just (AuthModel localAuth.token localAuth.user)


storeSession : Model -> SessionModel -> Model
storeSession model session =
    { model | session = session }


storeUi : Model -> UiModel -> Model
storeUi model ui =
    { model | ui = ui }


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }
