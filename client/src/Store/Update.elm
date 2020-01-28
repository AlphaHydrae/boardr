module Store.Update exposing (update)

import Api exposing (ApiGame, ApiGameList, ApiRoot, apiGameDecoder, apiGameListDecoder)
import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Http
import Platform.Cmd exposing (Cmd)
import Routes exposing (Route(..), toRoute)
import Store.Model exposing (DataModel, LocationModel, Model)
import Store.Msg exposing (Msg(..))
import Url exposing (Url)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiGameListRetrieved res ->
            case res of
                -- Store game list data from the API.
                Ok apiGameList ->
                    ( { model
                        | data = storeApiGameListData apiGameList model.data
                        , ui = setVisibleHomeGames apiGameList
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
                                -- FIXME: use URI template library
                                { url = String.replace "{id}" id apiRoot.gameLink.href
                                , expect = Http.expectJson ApiGameRetrieved apiGameDecoder
                                }
                            )

                        _ ->
                            ( newModel, Cmd.none )

                -- FIXME: handle ApiRootRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

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


setVisibleHomeGames : ApiGameList -> List String
setVisibleHomeGames apiGameList =
    List.map (\g -> g.id) apiGameList.games


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }
