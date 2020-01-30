module Store.Update exposing (update)

import Api exposing (ApiGame, ApiGameList, ApiIdentity, ApiRoot)
import Api.Req exposing (createLocalIdentity, createUser, retrieveGame, retrieveGameList)
import Browser
import Browser.Navigation as Nav
import Dict
import Pages.Register.Page as RegisterPage
import Platform.Cmd exposing (Cmd)
import Routes exposing (Route(..), toRoute)
import Store.Model exposing (DataModel, LocationModel, Model, UiModel)
import Store.Msg exposing (Msg(..))
import Url exposing (Url)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        ApiCreateUserResponseReceived _ ->
            ( model, Cmd.none )

        ApiGameListRetrieved res ->
            case res of
                -- Store game list data from the API.
                Ok apiGameList ->
                    ( { model
                        | data = storeApiGameListData apiGameList model.data
                        , ui = setVisibleHomeGames apiGameList model.ui
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
                    ( { model | data = storeApiGameData apiGame model.data }
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

        EditRegisterEmail _ ->
            ( msg |> RegisterPage.store model.ui |> storeUi model, Cmd.none )

        EditRegisterUsername _ ->
            ( msg |> RegisterPage.store model.ui |> storeUi model, Cmd.none )

        SubmitRegisterForm ->
            ( model
            , case model.data.root of
                Just apiRoot ->
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


storeData : Model -> DataModel -> Model
storeData model data =
    { model | data = data }


storeApiGameData : ApiGame -> DataModel -> DataModel
storeApiGameData apiGame data =
    { data | games = Dict.insert apiGame.id apiGame data.games }


storeApiGameListData : ApiGameList -> DataModel -> DataModel
storeApiGameListData apiGameList data =
    { data | games = List.foldl (\g d -> Dict.insert g.id g d) data.games apiGameList.games }


storeApiIdentity : DataModel -> ApiIdentity -> DataModel
storeApiIdentity data apiIdentity =
    { data | identities = Dict.insert apiIdentity.id apiIdentity data.identities }


storeApiRoot : DataModel -> ApiRoot -> DataModel
storeApiRoot data apiRoot =
    { data | root = Just apiRoot }


storeUi : Model -> UiModel -> Model
storeUi model ui =
    { model | ui = ui }


setVisibleHomeGames : ApiGameList -> UiModel -> UiModel
setVisibleHomeGames apiGameList ui =
    { ui | home = List.map (\g -> g.id) apiGameList.games }


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }
