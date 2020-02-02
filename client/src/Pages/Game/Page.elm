module Pages.Game.Page exposing (init, updateUi, view, viewModel)

import Api.Model exposing (ApiGame, ApiGameState(..))
import Dict
import Flags exposing (Flags)
import Html exposing (Html, li, p, strong, text, ul)
import Pages.Game.Model exposing (Model, ViewModel)
import Pages.Game.Msg exposing (Msg(..))
import Routes exposing (Route(..))
import Store.Model exposing (UiModel)
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


updateUi : UiModel -> Msg -> UiModel
updateUi model msg =
    { model | game = update model.game msg }


viewModel : String -> Store.Model.Model -> ViewModel
viewModel id model =
    case ( model.ui.game, Dict.get id model.data.games ) of
        ( Refreshing _, Just apiGame ) ->
            Refreshing apiGame

        -- TODO: introduce Cached variant of RemoteData
        ( _, Just apiGame ) ->
            Loaded apiGame

        ( Loading, _ ) ->
            Loading

        ( Error err, _ ) ->
            Error err

        ( _, Nothing ) ->
            Loading


view : ViewModel -> Html msg
view model =
    p []
        [ case model of
            Loading ->
                text "Loading..."

            Loaded game ->
                viewGame game

            Refreshing game ->
                viewGame game

            Error _ ->
                text "Could not load game."
        ]


viewGame : ApiGame -> Html msg
viewGame apiGame =
    ul []
        [ li []
            [ strong [] [ text "State:" ]
            , text " "
            , text
                (case apiGame.state of
                    WaitingForPlayers ->
                        "Waiting for players..."

                    Playing ->
                        "Playing"

                    Draw ->
                        "Draw"

                    Win ->
                        "Win!"
                )
            ]
        ]
