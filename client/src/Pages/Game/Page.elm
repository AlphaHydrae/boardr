module Pages.Game.Page exposing (init, updateUi, view, viewModel)

import Api.Model exposing (ApiGame, ApiGameState(..))
import Dict
import Flags exposing (Flags)
import Html exposing (Html, a, button, div, li, p, strong, text, ul)
import Html.Attributes exposing (href, type_)
import Html.Events exposing (onClick)
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

        ApiGamePagePlayerCreated _ ->
            model

        ApiGamePagePossibleActionsRetrieved res ->
            case res of
                Ok apiPossibleActionList ->
                    { model
                        | gameId = Loaded apiPossibleActionList.game.id
                        , possibleActions = Loaded apiPossibleActionList
                    }

                Err err ->
                    { model | possibleActions = Error err }

        JoinGame _ ->
            model

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
    , joinable =
        case ( Dict.get id model.data.games, model.session ) of
            ( Just apiGame, Just auth ) ->
                List.all
                    (\p -> p.gameLink.href /= apiGame.selfLink.href || p.userLink.href /= auth.user.selfLink.href)
                    (Dict.values model.data.players)

            _ ->
                False
    , possibleActions = model.ui.game.possibleActions
    }


view : ViewModel -> Html Msg
view model =
    div []
        [ p []
            [ a [ href "/" ] [ text "Home" ]
            ]
        , p []
            (case model.game of
                NotAsked ->
                    [ text "Loading..." ]

                Loading ->
                    [ text "Loading..." ]

                Loaded game ->
                    viewGame game model.joinable

                Refreshing game ->
                    viewGame game model.joinable

                Error _ ->
                    [ text "Could not load game." ]
            )
        ]


viewGame : ApiGame -> Bool -> List (Html Msg)
viewGame game joinable =
    ul []
        [ li []
            [ strong [] [ text "State:" ]
            , text " "
            , text
                (case game.state of
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
        :: viewGameControls game joinable


viewGameControls : ApiGame -> Bool -> List (Html Msg)
viewGameControls game joinable =
    if joinable then
        [ button [ onClick (JoinGame game), type_ "button" ] [ text "Join" ]
        ]

    else
        []
