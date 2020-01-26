module Pages.Home.Page exposing (init, selector, update, view)

import Dict exposing (Dict)
import Flags exposing (Flags)
import Html exposing (Html, a, div, h1, li, p, text, ul)
import Html.Attributes exposing (href)
import Msg exposing (Msg)
import Pages.Home.Model exposing (Model, ViewModel)
import Store.Model
import Utils.Api exposing (ApiGame)


init : Flags -> Model
init _ =
    Model []


selector : Store.Model.Model -> ViewModel
selector model =
    { displayedGames = selectDisplayedGames model.ui.home.displayedGameIds model.data.games }


selectDisplayedGames : List String -> Dict String ApiGame -> List ApiGame
selectDisplayedGames ids dict =
    List.filterMap (\id -> Dict.get id dict) ids


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.ApiGameListRetrieved (Ok apiGameList) ->
            ( { model | displayedGameIds = apiGameList.embedded.games |> List.map (\g -> g.links.self.href) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : ViewModel -> Html msg
view model =
    div []
        [ h1 [] [ text "Boardr" ]
        , p []
            [ a [ href "/stats" ] [ text "Stats" ]
            ]
        , viewGamesList model.displayedGames
        ]


viewGamesList : List ApiGame -> Html msg
viewGamesList games =
    ul []
        (List.map viewGame games)


viewGame : ApiGame -> Html msg
viewGame game =
    li []
        [ text (viewGameTitle game) ]


viewGameTitle : ApiGame -> String
viewGameTitle game =
    case game.title of
        Just title ->
            title

        Nothing ->
            game.rules
