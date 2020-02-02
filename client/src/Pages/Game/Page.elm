module Pages.Game.Page exposing (init, view, viewModel)

import Dict
import Flags exposing (Flags)
import Html exposing (Html, p, text)
import Pages.Game.Model exposing (Model, ViewModel)
import Pages.Game.Msg exposing (Msg(..))
import Routes exposing (Route(..))
import Store.Model
import Types exposing (RemoteData(..))


init : Flags -> Model
init _ =
    Loading


update : Model -> Msg -> Model
update model msg =
    case msg of
        ApiGamePageGameRetrieved res ->
            case res of
                Ok apiGame ->
                    Loaded apiGame.id

                Err err ->
                    Error err

        RefreshGameState _ ->
            case model of
                Loaded apiGame ->
                    Refreshing apiGame

                _ ->
                    model


viewModel : String -> Store.Model.Model -> ViewModel
viewModel id model =
    case ( model.ui.game, Dict.get id model.data.games ) of
        ( Loading, _ ) ->
            Loading

        ( _, Nothing ) ->
            Loading

        ( Loaded _, Just apiGame ) ->
            Loaded apiGame

        ( Refreshing _, Just apiGame ) ->
            Refreshing apiGame

        ( Error err, _ ) ->
            Error err


view : ViewModel -> Html msg
view model =
    p []
        [ text
            (case model of
                Loading ->
                    "Loading..."

                Loaded game ->
                    game.rules

                Refreshing game ->
                    game.rules

                Error _ ->
                    "Could not load game."
            )
        ]
