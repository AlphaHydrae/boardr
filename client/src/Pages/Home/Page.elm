module Pages.Home.Page exposing (init, view, viewModel)

import Api exposing (ApiGame)
import Dict exposing (Dict)
import Flags exposing (Flags)
import Html exposing (Html, a, div, h1, li, p, text, ul)
import Html.Attributes exposing (href)
import Pages.Home.Model exposing (Model, ViewModel)
import Store.Model


init : Flags -> Model
init _ =
    []


selectDisplayedGames : List String -> Dict String ApiGame -> List ApiGame
selectDisplayedGames ids dict =
    List.filterMap (\id -> Dict.get id dict) ids


viewModel : Store.Model.Model -> ViewModel
viewModel model =
    selectDisplayedGames model.ui model.data.games


view : ViewModel -> Html msg
view vm =
    div []
        [ h1 [] [ text "Boardr" ]
        , p []
            [ a [ href "/stats" ] [ text "Stats" ]
            ]
        , viewGamesList vm
        ]


viewGamesList : List ApiGame -> Html msg
viewGamesList games =
    ul []
        (List.map viewGame games)


viewGame : ApiGame -> Html msg
viewGame game =
    li []
        [ a [ href ("/games/" ++ game.id) ] [ text (viewGameTitle game) ] ]


viewGameTitle : ApiGame -> String
viewGameTitle game =
    case game.title of
        Just title ->
            title

        Nothing ->
            game.rules
