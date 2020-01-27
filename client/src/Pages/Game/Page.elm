module Pages.Game.Page exposing (view, viewModel)

import Dict
import Html exposing (Html, p, text)
import Pages.Game.Model exposing (ViewModel)
import Routes exposing (Route(..))
import Store.Model


viewModel : Store.Model.Model -> ViewModel
viewModel model =
    case model.location.route of
        GameRoute id ->
            Dict.get id model.data

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
