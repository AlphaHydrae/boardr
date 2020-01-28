module Pages.Game.Page exposing (view, viewModel)

import Dict
import Html exposing (Html, p, text)
import Pages.Game.Model exposing (ViewModel)
import Routes exposing (Route(..))
import Store.Model


viewModel : String -> Store.Model.Model -> ViewModel
viewModel gameId model =
    Dict.get gameId model.data.games


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
