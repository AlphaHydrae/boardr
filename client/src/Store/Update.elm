module Store.Update exposing (update)

import Api exposing (ApiGame, ApiGameList, apiGameDecoder, apiGameListDecoder)
import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Http
import Routes exposing (Route(..), toRoute)
import Store.Model exposing (LocationModel, Model)
import Store.Msg exposing (Msg(..))
import Url exposing (Url)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiGameListRetrieved res ->
            case res of
                Ok apiGameList ->
                    ( { model
                        | data = storeApiGameList apiGameList model.data
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
                    ( { model | data = storeApiGame apiGame model.data }
                    , Cmd.none
                    )

                -- FIXME: handle ApiGameRetrieved Err
                Err _ ->
                    ( model, Cmd.none )

        ApiRootRetrieved res ->
            case res of
                Ok apiRoot ->
                    case model.location.route of
                        HomeRoute ->
                            ( model
                            , Http.get
                                { url = apiRoot.gamesLink.href
                                , expect = Http.expectJson ApiGameListRetrieved apiGameListDecoder
                                }
                            )

                        GameRoute id ->
                            ( model
                            , Http.get
                                -- FIXME: use URI template library
                                { url = String.replace "{id}" id apiRoot.gameLink.href
                                , expect = Http.expectJson ApiGameRetrieved apiGameDecoder
                                }
                            )

                        StatsRoute ->
                            ( model, Cmd.none )

                        NotFound ->
                            ( model, Cmd.none )

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
            ( { model | location = updateLocation url (toRoute url) model.location }
            , Cmd.none
            )


storeApiGame : ApiGame -> Dict String ApiGame -> Dict String ApiGame
storeApiGame apiGame data =
    Dict.insert apiGame.id apiGame data


storeApiGameList : ApiGameList -> Dict String ApiGame -> Dict String ApiGame
storeApiGameList apiGameList data =
    List.foldl (\g d -> Dict.insert g.links.self.href g d) data apiGameList


setVisibleHomeGames : ApiGameList -> List String
setVisibleHomeGames apiGameList =
    List.map (\g -> g.links.self.href) apiGameList


updateLocation : Url -> Route -> LocationModel -> LocationModel
updateLocation url route location =
    { location | url = url, route = route }
