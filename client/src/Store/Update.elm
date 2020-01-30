module Store.Update exposing (update)

import Api.Model exposing (ApiGame, ApiGameList, ApiIdentity, ApiLocalAuthentication, ApiRoot, ApiUserWithToken, apiUserWithoutToken)
import Api.Req exposing (authenticateLocally, createLocalIdentity, createUser, retrieveGame, retrieveGameList)
import Browser
import Browser.Navigation as Nav
import Dict
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

        ApiCreateLocalIdentityResponseReceived res ->
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

                -- FIXME: handle ApiCreateLocalIdentityResponseReceived Err
                ( Err _, _ ) ->
                    ( model, Cmd.none )

        ApiCreateUserResponseReceived res ->
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

                -- FIXME: handle ApiCreateUserResponseReceived Err
                Err _ ->
                    ( model, Cmd.none )

        ApiGameListRetrieved res ->
            case res of
                -- Store game list data from the API.
                Ok apiGameList ->
                    ( { model
                        | data = apiGameList |> storeApiGameList model.data
                        , ui = apiGameList |> storeVisibleHomeGames model.ui
                      }
                    , Cmd.none
                    )

                -- FIXME: handle ApiGameListRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

        ApiGameRetrieved res ->
            case res of
                -- Store game data from the API.
                Ok apiGame ->
                    ( apiGame |> storeApiGame model.data |> storeData model
                    , Cmd.none
                    )

                -- FIXME: handle ApiGameRetrieved Err
                Err _ ->
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
                            ( newModel, retrieveGameList apiRoot )

                        -- Retrieve the current game from the API on the game page.
                        GameRoute id ->
                            ( newModel, retrieveGame id apiRoot )

                        _ ->
                            ( newModel, Cmd.none )

                -- FIXME: handle ApiRootRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

        LoginPage sub ->
            ( sub |> LoginPage.store model.ui |> storeUi model
            , case ( sub, model.data.root ) of
                ( SubmitLoginForm, Just apiRoot ) ->
                    authenticateLocally model.ui.login apiRoot

                _ ->
                    Cmd.none
            )

        LogOut ->
            let
                newSession =
                    forgetAuth model.session
            in
            ( newSession |> storeSession model, saveSession (sessionEncoder newSession) )

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
                            retrieveGameList root

                        _ ->
                            Cmd.none

                Nothing ->
                    Cmd.none
            )


forgetAuth : SessionModel -> SessionModel
forgetAuth _ =
    Nothing


storeApiGame : DataModel -> ApiGame -> DataModel
storeApiGame data apiGame =
    { data | games = Dict.insert apiGame.id apiGame data.games }


storeApiGameList : DataModel -> ApiGameList -> DataModel
storeApiGameList data apiGameList =
    { data | games = List.foldl (\g d -> Dict.insert g.id g d) data.games apiGameList.games }


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
storeLocalAuthentication session localAuth =
    Just (AuthModel localAuth.token localAuth.user)


storeSession : Model -> SessionModel -> Model
storeSession model session =
    { model | session = session }


storeUi : Model -> UiModel -> Model
storeUi model ui =
    { model | ui = ui }


storeVisibleHomeGames : UiModel -> ApiGameList -> UiModel
storeVisibleHomeGames ui apiGameList =
    { ui | home = List.map (\g -> g.id) apiGameList.games }


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }
