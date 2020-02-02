module Pages.Home.Page exposing (init, updateUi, view, viewModel)

import Api.Model exposing (ApiGame, ApiGameList, ApiUser)
import Dict exposing (Dict)
import Flags exposing (Flags)
import Html exposing (Html, a, button, div, h1, li, p, text, ul)
import Html.Attributes exposing (href, type_)
import Html.Events exposing (onClick)
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

        LogOut ->
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
    }


view : ViewModel -> Html Msg
view vmodel =
    div []
        [ h1 [] [ text "Boardr" ]
        , p [] (viewNavLinks vmodel)
        , viewGameCreationControls vmodel.currentUser
        , viewGameList vmodel.displayedGames
        ]


viewNavLinks : ViewModel -> List (Html Msg)
viewNavLinks vmodel =
    a [ href "/stats" ] [ text "Stats" ] :: viewAuthNavLinks vmodel


viewAuthNavLinks : ViewModel -> List (Html Msg)
viewAuthNavLinks vmodel =
    case vmodel.currentUser of
        Just _ ->
            [ a [ href "#", onClick LogOut ] [ text "Log out" ] ]

        Nothing ->
            [ a [ href "/login" ] [ text "Log in" ]
            , a [ href "/register" ] [ text "Register" ]
            ]


viewGameCreationControls : Maybe ApiUser -> Html Msg
viewGameCreationControls currentUser =
    case currentUser of
        Just _ ->
            button [ onClick CreateGame, type_ "button" ] [ text "Create a game" ]

        Nothing ->
            a [ href "/login" ] [ text "Join the fun" ]


viewGameList : RemoteData (List ApiGame) -> Html msg
viewGameList displayedGames =
    case displayedGames of
        NotAsked ->
            p [] [ text "Loading..." ]

        Loading ->
            p [] [ text "Loading..." ]

        Loaded games ->
            ul []
                (List.map viewGame games)

        Refreshing games ->
            ul []
                (List.map viewGame games)

        Error _ ->
            p [] [ text "Could not load games." ]


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
