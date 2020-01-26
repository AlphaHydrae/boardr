module Pages.Game.Page exposing (selector, view)

import Dict
import Html exposing (Html, p, text)
import Pages.Game.Model exposing (ViewModel)
import Routes exposing (Route(..))
import Store.Model


selector : Store.Model.Model -> ViewModel
selector model =
    case model.location.route of
        GameRoute id ->
            Dict.get id model.data.games

        _ ->
            Nothing


view : ViewModel -> Html msg
view model =
    p []
        [ text
            (case model of
                Just game ->
                    game.rules

                _ ->
                    "Loading..."
            )
        ]
