module Pages.Home.Page exposing (init, updateUi, view, viewModel)

import Api.Model exposing (ApiGame, ApiGameList, ApiUser)
import DateFormat
import Dict exposing (Dict)
import Flags exposing (Flags)
import Html exposing (Html, a, button, div, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, href, type_)
import Html.Events exposing (onClick)
import ISO8601
import Pages.Home.Model exposing (Model, ViewModel)
import Pages.Home.Msg exposing (Msg(..))
import Store.Model exposing (UiModel)
import Types exposing (RemoteData(..))


init : Flags -> Model
init _ =
    Loading


selectDisplayedGames : List String -> Dict String ApiGame -> List ApiGame
selectDisplayedGames ids dict =
    List.filterMap (\id -> Dict.get id dict) ids


storeDisplayedGames : Model -> ApiGameList -> Model
storeDisplayedGames _ apiGameList =
    Loaded (List.map .id apiGameList.games)


update : Model -> Msg -> Model
update model msg =
    case msg of
        ApiHomePageGameCreated _ ->
            model

        ApiHomePageGamesRetrieved res ->
            case res of
                Ok apiGameList ->
                    storeDisplayedGames model apiGameList

                Err err ->
                    Error err

        CreateGame ->
            model

        RefreshDisplayedGames _ ->
            model


updateUi : UiModel -> Msg -> UiModel
updateUi ui msg =
    { ui | home = update ui.home msg }


viewModel : Store.Model.Model -> ViewModel
viewModel model =
    { currentUser = Maybe.map .user model.session
    , displayedGames =
        case model.ui.home of
            NotAsked ->
                Loading

            Loading ->
                Loading

            Loaded ids ->
                Loaded (selectDisplayedGames ids model.data.games)

            Refreshing ids ->
                Loaded (selectDisplayedGames ids model.data.games)

            Error err ->
                Error err
    , zone = model.ui.zone
    }


view : ViewModel -> Html Msg
view vmodel =
    div [ class "col-12 col-lg-6 offset-lg-3" ]
        [ viewGameCreationControls vmodel.currentUser
        , viewGameList vmodel
        ]


viewGameCreationControls : Maybe ApiUser -> Html Msg
viewGameCreationControls currentUser =
    div [ class "mb-4 mt-3 text-center" ]
        [ case currentUser of
            Just _ ->
                button [ class "btn btn-lg btn-primary", onClick CreateGame, type_ "button" ] [ text "Create a game" ]

            Nothing ->
                a [ class "btn btn-lg btn-primary", href "/login" ] [ text "Join the fun" ]
        ]


viewGameList : ViewModel -> Html msg
viewGameList vmodel =
    table [ class "table" ]
        [ thead []
            [ tr []
                [ th [ class "border-top-0" ]
                    [ text "Game" ]
                , th
                    [ class "border-top-0" ]
                    [ text "Date" ]
                ]
            ]
        , tbody []
            (case vmodel.displayedGames of
                NotAsked ->
                    [ viewLoading ]

                Loading ->
                    [ viewLoading ]

                Loaded games ->
                    List.map (viewGame vmodel) games

                Refreshing games ->
                    List.map (viewGame vmodel) games

                Error _ ->
                    [ tr [ class "table-warning" ]
                        [ td []
                            [ text "Could not load games."
                            ]
                        ]
                    ]
            )
        ]


viewLoading : Html msg
viewLoading =
    tr [ class "table-secondary" ]
        [ td [ colspan 2 ]
            [ span [ class "text-muted" ] [ text "Loading..." ]
            ]
        ]


viewGame : ViewModel -> ApiGame -> Html msg
viewGame vmodel game =
    tr []
        [ td []
            [ a [ href ("/games/" ++ game.id) ] [ text (viewGameTitle game) ]
            ]
        , td []
            [ viewGameDate vmodel game ]
        ]


viewGameDate : ViewModel -> ApiGame -> Html msg
viewGameDate vmodel game =
    case vmodel.zone of
        Just zone ->
            case ISO8601.fromString game.createdAt of
                Ok iso8601 ->
                    text
                        (DateFormat.format
                            [ DateFormat.monthNameFull
                            , DateFormat.text " "
                            , DateFormat.dayOfMonthSuffix
                            , DateFormat.text ", "
                            , DateFormat.yearNumber
                            , DateFormat.text " at "
                            , DateFormat.hourMilitaryFixed
                            , DateFormat.text ":"
                            , DateFormat.minuteFixed
                            ]
                            zone
                            (iso8601 |> ISO8601.toPosix)
                        )

                _ ->
                    text "-"

        _ ->
            text "-"


viewGameTitle : ApiGame -> String
viewGameTitle game =
    case game.title of
        Just title ->
            title

        Nothing ->
            case game.rules of
                "tic-tac-toe" ->
                    "Tic-Tac-Toe"

                _ ->
                    game.rules
