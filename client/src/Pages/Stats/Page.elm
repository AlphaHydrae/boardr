module Pages.Stats.Page exposing (init, updateUi, view)

import Api.Model exposing (ApiNodeStats)
import Dict
import Flags exposing (Flags)
import Html exposing (Html, div, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class)
import Pages.Stats.Model exposing (Model)
import Pages.Stats.Msg exposing (Msg(..))
import Store.Model exposing (UiModel)
import Types exposing (RemoteData(..), getRemoteData)


init : Flags -> Model
init _ =
    Loading


update : Model -> Msg -> Model
update model msg =
    case msg of
        ApiStatsRetrieved res ->
            case res of
                Ok stats ->
                    Loaded stats

                Err err ->
                    Error err

        RefreshApiStats _ ->
            case getRemoteData model of
                Just stats ->
                    Refreshing stats

                _ ->
                    model


updateUi : UiModel -> Msg -> UiModel
updateUi ui msg =
    { ui | stats = update ui.stats msg }


view : Model -> Html Msg
view model =
    div [ class "col-12 col-lg-6 offset-lg-3" ]
        (case getRemoteData model of
            Just stats ->
                [ table [ class "table" ]
                    [ thead []
                        [ tr []
                            [ th []
                                [ text "Entity" ]
                            , th []
                                [ text "State" ]
                            , th []
                                [ text "Count" ]
                            ]
                        ]
                    , tbody []
                        [ tr []
                            [ th [] [ text "Identities" ]
                            , td [] [ text "-" ]
                            , td [] [ text (String.fromInt stats.identities) ]
                            ]
                        , tr []
                            [ th [] [ text "Users" ]
                            , td [] [ text "-" ]
                            , td [] [ text (String.fromInt stats.users) ]
                            ]
                        , tr []
                            [ th [] [ text "Games" ]
                            , td [] [ text "Waiting For Players" ]
                            , td [] [ text (String.fromInt stats.games.waitingForPlayers) ]
                            ]
                        , tr []
                            [ th [] [ text "Games" ]
                            , td [] [ text "Playing" ]
                            , td [] [ text (String.fromInt stats.games.playing) ]
                            ]
                        , tr
                            [ class
                                (case stats.games.inactive of
                                    0 ->
                                        ""

                                    _ ->
                                        "table-danger"
                                )
                            ]
                            [ th [] [ text "Games" ]
                            , td [] [ text "Inactive" ]
                            , td [] [ text (String.fromInt stats.games.inactive) ]
                            ]
                        , tr []
                            [ th [] [ text "Games" ]
                            , td [] [ text "Draw" ]
                            , td [] [ text (String.fromInt stats.games.draw) ]
                            ]
                        , tr []
                            [ th [] [ text "Games" ]
                            , td [] [ text "Win" ]
                            , td [] [ text (String.fromInt stats.games.win) ]
                            ]
                        , tr []
                            [ th [] [ text "Actions" ]
                            , td [] [ text "-" ]
                            , td [] [ text (String.fromInt stats.actions) ]
                            ]
                        ]
                    ]
                , table [ class "table mt-5" ]
                    [ thead []
                        [ tr []
                            [ th [] [ text "Node" ]
                            , th [] [ text "Game Servers" ]
                            , th [] [ text "Swarm Processes" ]
                            ]
                        ]
                    , tbody []
                        (List.map viewNodeStats (Dict.toList stats.nodes))
                    ]
                ]

            Nothing ->
                [ div [ class "alert alert-secondary" ] [ text "No stats available" ] ]
        )


viewNodeStats : ( String, ApiNodeStats ) -> Html msg
viewNodeStats ( node, stats ) =
    tr []
        [ td [] [ text node ]
        , td [] [ text (String.fromInt stats.gameServers) ]
        , td [] [ text (String.fromInt stats.swarmProcesses) ]
        ]
