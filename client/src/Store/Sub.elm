module Store.Sub exposing (subscriptions)

import Api.Model exposing (ApiGameState(..))
import Dict
import Pages.Game.Msg exposing (Msg(..))
import Pages.Home.Msg exposing (Msg(..))
import Pages.Stats.Msg exposing (Msg(..))
import Routes exposing (Route(..))
import Store.Model exposing (Model)
import Store.Msg exposing (Msg(..))
import Time
import Types exposing (RemoteData(..))


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.location.route of
        HomeRoute ->
            case model.ui.home of
                Loaded _ ->
                    Time.every 1000 (\t -> HomePage (RefreshDisplayedGames t))

                _ ->
                    Sub.none

        -- FIXME: do not refresh game state while joining
        GameRoute id ->
            case Maybe.map .state (Dict.get id model.data.games) of
                Just WaitingForPlayers ->
                    Time.every 1000 (\t -> GamePage (RefreshGameState t))

                Just Playing ->
                    Time.every 1000 (\t -> GamePage (RefreshOngoingGameState t))

                _ ->
                    Sub.none

        LoginRoute ->
            Sub.none

        RegisterRoute ->
            Sub.none

        StatsRoute ->
            Time.every 7500 (\t -> StatsPage (RefreshApiStats t))

        NotFound ->
            Sub.none
