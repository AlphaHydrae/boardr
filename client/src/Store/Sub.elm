module Store.Sub exposing (subscriptions)

import Pages.Game.Msg exposing (Msg(..))
import Pages.Home.Msg exposing (Msg(..))
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

        GameRoute _ ->
            Time.every 1000 (\t -> GamePage (RefreshGameState t))

        LoginRoute ->
            Sub.none

        RegisterRoute ->
            Sub.none

        StatsRoute ->
            Sub.none

        NotFound ->
            Sub.none
