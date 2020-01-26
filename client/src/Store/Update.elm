module Store.Update exposing (update)

import Browser
import Browser.Navigation as Nav
import Dict
import Msg exposing (Msg)
import Pages.Home.Page as HomePage
import Routes exposing (toRoute)
import Store.Model exposing (BusinessDataModel, LocationModel, Model, UiModel)
import Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
        |> (\( m, cmd ) -> Tuple.mapFirst (\d -> { m | data = d }) (updateBusinessDataModel msg ( m.data, cmd )))
        |> (\( m, cmd ) -> Tuple.mapFirst (\l -> { m | location = l }) (updateLocationModel msg ( m.location, cmd )))
        |> (\( m, cmd ) -> Tuple.mapFirst (\ui -> { m | ui = ui }) (updateUiModel msg ( m, cmd )))


updateBusinessDataModel : Msg -> ( BusinessDataModel, Cmd Msg ) -> ( BusinessDataModel, Cmd Msg )
updateBusinessDataModel msg ( model, cmd ) =
    case msg of
        Msg.ApiGameListRetrieved res ->
            case res of
                Ok apiGameList ->
                    ( { model | games = List.foldl (\g d -> Dict.insert g.links.self.href g d) model.games apiGameList }, cmd )

                Err _ ->
                    ( model, cmd )

        _ ->
            ( model, cmd )


updateLocationModel : Msg -> ( LocationModel, Cmd Msg ) -> ( LocationModel, Cmd Msg )
updateLocationModel msg ( model, cmd ) =
    case msg of
        Msg.RequestUrl urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Cmd.batch [ cmd, Nav.pushUrl model.key (Url.toString url) ] )

                Browser.External href ->
                    ( model, Cmd.batch [ cmd, Nav.load href ] )

        Msg.UrlChanged url ->
            ( { model | url = url, route = toRoute url }
            , cmd
            )

        _ ->
            ( model, cmd )


updateUiModel : Msg -> ( Model, Cmd Msg ) -> ( UiModel, Cmd Msg )
updateUiModel msg ( model, cmd ) =
    ( model.ui, cmd )
    |> (\( ui, uiCmd ) -> Tuple.mapBoth (\state -> { ui | home = state }) (\homeCmd -> Cmd.batch [uiCmd, homeCmd]) (HomePage.update msg ui.home))