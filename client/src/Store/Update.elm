module Store.Update exposing (update)

import Api exposing (ApiGame, ApiGameList, ApiIdentity, ApiRoot, apiGameDecoder, apiIdentityDecoder, apiGameListDecoder, apiUserDecoder)
import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Http
import Json.Encode as E
import Pages.Register.Page as RegisterPage
import Platform.Cmd exposing (Cmd)
import Routes exposing (Route(..), toRoute)
import Store.Model exposing (DataModel, LocationModel, Model, UiModel)
import Store.Msg exposing (Msg(..))
import Url exposing (Url)
import Url.Interpolate exposing (interpolate)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiCreateIdentityResponseReceived res ->
            ( model, Cmd.none )

        ApiCreateUserResponseReceived res ->
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
                            { model | data = storeApiRoot apiRoot model.data }
                    in
                    case model.location.route of
                        -- Retrieve the game list from the API on the home page.
                        HomeRoute ->
                            ( newModel, retrieveGameList apiRoot )

                        -- Retrieve the current game from the API on the game page.
                        GameRoute id ->
                            ( newModel
                            , Http.get
                                { url = interpolate apiRoot.gameLink.href (Dict.fromList [ ( "{id}", id ) ])
                                , expect = Http.expectJson ApiGameRetrieved apiGameDecoder
                                }
                            )

                        _ ->
                            ( newModel, Cmd.none )

                -- FIXME: handle ApiRootRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

        EditRegisterEmail value ->
            ( updateUi (RegisterPage.updateUi msg model.ui) model, Cmd.none )

        SubmitRegisterForm ->
            ( model
            , case model.data.root of
                Just apiRoot ->
                    Http.post
                        { url = apiRoot.identitiesLink.href
                        , body = Http.jsonBody (E.object [ ( "email", E.string model.ui.register.email ), ( "provider", E.string "local" ) ])
                        , expect = Http.expectJson ApiCreateIdentityResponseReceived apiIdentityDecoder
                        }

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


retrieveGameList : ApiRoot -> Cmd Msg
retrieveGameList apiRoot =
    Http.get
        { url = apiRoot.gamesLink.href ++ "?embed=boardr:players"
        , expect = Http.expectJson ApiGameListRetrieved apiGameListDecoder
        }


storeApiGameData : ApiGame -> DataModel -> DataModel
storeApiGameData apiGame data =
    { data | games = Dict.insert apiGame.id apiGame data.games }


storeApiGameListData : ApiGameList -> DataModel -> DataModel
storeApiGameListData apiGameList data =
    { data | games = List.foldl (\g d -> Dict.insert g.id g d) data.games apiGameList.games }


storeApiRoot : ApiRoot -> DataModel -> DataModel
storeApiRoot apiRoot data =
    { data | root = Just apiRoot }


setVisibleHomeGames : ApiGameList -> UiModel -> UiModel
setVisibleHomeGames apiGameList ui =
    { ui | home = List.map (\g -> g.id) apiGameList.games }


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }


updateUi : UiModel -> Model -> Model
updateUi ui model =
    { model | ui = ui }
