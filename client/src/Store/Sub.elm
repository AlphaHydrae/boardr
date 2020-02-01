module Store.Sub exposing (subscriptions)

import Pages.Home.Msg exposing (Msg(..))
import Routes exposing (Route(..))
import Store.Model exposing (Model)
import Store.Msg exposing (Msg(..))
import Time


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.location.route of
        HomeRoute ->
            Time.every 1000 (\t -> HomePage (RefreshDisplayedGames t))

        GameRoute _ ->
            Sub.none

        LoginRoute ->
            Sub.none

        RegisterRoute ->
            Sub.none

        StatsRoute ->
            Sub.none

        NotFound ->
            Sub.none
