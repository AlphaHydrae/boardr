module Pages.Game.Page exposing (init, updateUi, view, viewModel)

import Api.Model exposing (ApiGame, ApiGameState(..))
import Dict
import Flags exposing (Flags)
import Html exposing (Html, a, div, li, p, strong, text, ul)
import Html.Attributes exposing (href)
import Pages.Game.Model exposing (Model, ViewModel)
import Pages.Game.Msg exposing (Msg(..))
import Routes exposing (Route(..))
import Store.Model exposing (UiModel)
import Types exposing (RemoteData(..))


init : Flags -> Model
init _ =
    { gameId = Loading
    , possibleActions = NotAsked
    }


update : Model -> Msg -> Model
update model msg =
    case msg of
        ApiGamePageGameRetrieved res ->
            case res of
                Ok apiGame ->
                    { model | gameId = Loaded apiGame.id }

                Err err ->
                    { model | gameId = Error err }

        ApiGamePagePossibleActionsRetrieved res ->
            case res of
                Ok apiPossibleActionList ->
                    { model
                        | gameId = Loaded apiPossibleActionList.game.id
                        , possibleActions = Loaded apiPossibleActionList
                    }

                Err err ->
                    { model | possibleActions = Error err }

        RefreshGamePossibleActions _ ->
            case model.possibleActions of
                NotAsked ->
                    { model | possibleActions = Loading }

                Loaded possibleActions ->
                    { model | possibleActions = Refreshing possibleActions }

                _ ->
                    model

        RefreshGameState _ ->
            case model.gameId of
                Loaded gameId ->
                    { model | gameId = Refreshing gameId }

                _ ->
                    model


updateUi : UiModel -> Msg -> UiModel
updateUi model msg =
    { model | game = update model.game msg }


viewModel : String -> Store.Model.Model -> ViewModel
viewModel id model =
    { game =
        case ( model.ui.game.gameId, Dict.get id model.data.games ) of
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
    , possibleActions = model.ui.game.possibleActions
    }


view : ViewModel -> Html msg
view model =
    div []
        [ p [] [
            a [ href "/" ] [ text "Home" ]
        ]
        , p [] [
            case model.game of
                NotAsked ->
                    text "Loading..."

                Loading ->
                    text "Loading..."

                Loaded game ->
                    viewGame game

                Refreshing game ->
                    viewGame game

                Error _ ->
                    text "Could not load game."
        ]
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
