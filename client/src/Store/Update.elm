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
                        newModel = { model | data = storeApiRoot apiRoot model.data }
                    in
                    case model.location.route of
                        HomeRoute ->
                            ( newModel, retrieveGameList apiRoot )

                        GameRoute id ->
                            ( newModel
                            , Http.get
                                -- FIXME: use URI template library
                                { url = String.replace "{id}" id apiRoot.gameLink.href
                                , expect = Http.expectJson ApiGameRetrieved apiGameDecoder
                                }
                            )

                        StatsRoute ->
                            ( newModel, Cmd.none )

                        NotFound ->
                            ( newModel, Cmd.none )

                -- FIXME: handle ApiRootRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

        RequestUrl urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.location.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                route =
                    toRoute url
            in
            ( { model | location = updateLocation url route model.location }
            , case model.data.root of
                Just root ->
                    case route of
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
        { url = apiRoot.gamesLink.href
        , expect = Http.expectJson ApiGameListRetrieved apiGameListDecoder
        }


storeApiGameData : ApiGame -> DataModel -> DataModel
storeApiGameData apiGame data =
    { data | games = Dict.insert apiGame.id apiGame data.games }


storeApiGameListData : ApiGameList -> DataModel -> DataModel
storeApiGameListData apiGameList data =
    { data | games = List.foldl (\g d -> Dict.insert g.id g d) data.games apiGameList }


storeApiRoot : ApiRoot -> DataModel -> DataModel
storeApiRoot apiRoot data =
    { data | root = Just apiRoot }


setVisibleHomeGames : ApiGameList -> List String
setVisibleHomeGames apiGameList =
    List.map (\g -> g.id) apiGameList


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }
