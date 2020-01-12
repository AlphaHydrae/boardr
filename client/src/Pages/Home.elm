module Pages.Home exposing (page)

import Html exposing (Html, a, div, h1, p, text)
import Html.Attributes exposing (href)


page : Int -> Html msg
page _ =
    div []
        [ h1 [] [ text "Boardr" ]
        , p []
            [ a [ href "/stats" ] [ text "Stats" ]
            ]
        ]
