module Pages.Game.Page exposing (init, updateUi, view, viewModel)

import Api.Model exposing (ApiGame, ApiGameState(..), ApiPlayer, ApiPossibleActionList, ApiUser)
import Dict
import Flags exposing (Flags)
import Html exposing (Html, a, button, div, li, p, strong, table, td, text, tr, ul)
import Html.Attributes exposing (href, type_)
import Html.Events exposing (onClick)
import List.Extra
import Pages.Game.Model exposing (Model, ViewModel)
import Pages.Game.Msg exposing (Msg(..))
import Routes exposing (Route(..))
import Store.Model exposing (UiModel)
import Store.Session exposing (AuthModel)
import Types exposing (RemoteData(..), getRemoteData)


init : Flags -> Model
init _ =
    { board = NotAsked
    , gameId = Loading
    , possibleActions = NotAsked
    }


update : Model -> Msg -> Model
update model msg =
    case msg of
        ApiActionCreated ->
            model

        ApiBoardRetrieved res ->
            case res of
                Ok apiBoard ->
                    { model | board = Loaded apiBoard }

                Err err ->
                    { model | board = Error err }

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

        Play _ _ _ ->
            model

        RefreshGameState _ ->
            case model.gameId of
                Loaded gameId ->
                    { model | gameId = Refreshing gameId }

                _ ->
                    model

        RefreshOngoingGameState _ ->
            { model
                | board =
                    case model.board of
                        NotAsked ->
                            Loading

                        Loaded board ->
                            Refreshing board

                        _ ->
                            model.board
                , possibleActions =
                    case model.possibleActions of
                        NotAsked ->
                            Loading

                        Loaded possibleActions ->
                            Refreshing possibleActions

                        _ ->
                            model.possibleActions
            }


updateUi : UiModel -> Msg -> UiModel
updateUi model msg =
    { model | game = update model.game msg }


viewModel : String -> Store.Model.Model -> ViewModel
viewModel id model =
    { auth = model.session
    , board = model.ui.game.board
    , game =
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
    , players =
        case Dict.get id model.data.games of
            Just apiGame ->
                List.filter (\p -> p.gameLink.href == apiGame.selfLink.href) (Dict.values model.data.players)

            Nothing ->
                []
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
                    viewGame game model

                Refreshing game ->
                    viewGame game model

                Error _ ->
                    [ text "Could not load game." ]
            )
        ]


viewGame : ApiGame -> ViewModel -> List (Html Msg)
viewGame game vmodel =
    ul []
        [ li []
            [ strong [] [ text "State:" ]
            , text " "
            , text
                (case game.state of
                    WaitingForPlayers ->
                        "Waiting for players..."

                    Playing ->
                        viewOngoingGameState vmodel

                    Draw ->
                        "Draw"

                    Win ->
                        "Win!"
                )
            ]
        ]
        :: viewGameControls game vmodel.joinable
        ++ viewBoard vmodel


viewBoard : ViewModel -> List (Html Msg)
viewBoard vmodel =
    [ table []
        [ tr []
            [ cell vmodel 0 0
            , cell vmodel 1 0
            , cell vmodel 2 0
            ]
        , tr []
            [ cell vmodel 0 1
            , cell vmodel 1 1
            , cell vmodel 2 1
            ]
        , tr []
            [ cell vmodel 0 2
            , cell vmodel 1 2
            , cell vmodel 2 2
            ]
        ]
    ]


cell : ViewModel -> Int -> Int -> Html Msg
cell vmodel col row =
    td (cellAttrs vmodel col row) [ text (piece vmodel col row) ]


cellAttrs : ViewModel -> Int -> Int -> List (Html.Attribute Msg)
cellAttrs vmodel col row =
    case vmodel.auth of
        Just auth ->
            if isInGame auth.user vmodel then
                [ onClick (Play auth col row) ]

            else
                []

        Nothing ->
            []


piece : ViewModel -> Int -> Int -> String
piece vmodel col row =
    case getRemoteData vmodel.board of
        Just board ->
            case List.Extra.find (\p -> p.position == ( col, row )) board.data of
                Just p ->
                    case p.player of
                        1 -> "X"
                        _ -> "O"

                Nothing ->
                    "_"

        Nothing ->
            "_"



viewOngoingGameState : ViewModel -> String
viewOngoingGameState vmodel =
    case ( Maybe.map .user vmodel.auth, getRemoteData vmodel.possibleActions ) of
        ( Just user, Just actions ) ->
            if canPlay user actions vmodel then
                "Your turn"

            else if isInGame user vmodel then
                "Waiting for your opponent's move"

            else
                case currentPlayer actions vmodel of
                    Just player ->
                        "Waiting for player " ++ String.fromInt player.number ++ "'s move"

                    Nothing ->
                        "Waiting for the next move"

        ( _, Just actions ) ->
            case currentPlayer actions vmodel of
                Just player ->
                    "Waiting for player " ++ String.fromInt player.number ++ "'s move"

                Nothing ->
                    "Waiting for the next move"

        _ ->
            "Playing"


viewGameControls : ApiGame -> Bool -> List (Html Msg)
viewGameControls game joinable =
    if joinable then
        [ button [ onClick (JoinGame game), type_ "button" ] [ text "Join" ]
        ]

    else
        []


canPlay : ApiUser -> ApiPossibleActionList -> ViewModel -> Bool
canPlay user possibleActionList vmodel =
    Maybe.withDefault False (Maybe.map (\p -> p.userLink.href == user.selfLink.href) (currentPlayer possibleActionList vmodel))


isInGame : ApiUser -> ViewModel -> Bool
isInGame user vmodel =
    List.any (\p -> p.userLink.href == user.selfLink.href) vmodel.players


currentPlayer : ApiPossibleActionList -> ViewModel -> Maybe ApiPlayer
currentPlayer possibleActionList vmodel =
    List.head (List.filterMap (\a -> List.head (List.filter (\p -> p.selfLink.href == a.playerLink.href) vmodel.players)) possibleActionList.possibleActions)
