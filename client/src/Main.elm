module Main exposing (main)

import Api.Req exposing (retrieveRoot)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Flags exposing (Flags, ProgramFlags, defaultFlags, flagsDecoder)
import Html exposing (Html, a, div, nav, p, span, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Html.Lazy exposing (lazy)
import Json.Decode as Decode
import Pages.Game.Page as GamePage
import Pages.Home.Page as HomePage
import Pages.Login.Page as LoginPage
import Pages.Register.Page as RegisterPage
import Pages.Stats.Page as StatsPage
import Routes exposing (Route(..))
import Store.Init
import Store.Model exposing (Model)
import Store.Msg exposing (Msg(..))
import Store.Sub exposing (subscriptions)
import Store.Update exposing (update)
import Task
import Time
import Url


main : Program ProgramFlags Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = RequestUrl
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : ProgramFlags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    initWithFlags (parseProgramFlags flags) url key


initWithFlags : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
initWithFlags flags url key =
    ( Store.Init.init flags url key
    , Cmd.batch
        [ retrieveRoot flags.apiUrl
        , Task.perform TimeZoneRetrieved Time.here
        ]
    )


parseProgramFlags : Decode.Value -> Flags
parseProgramFlags flags =
    case Decode.decodeValue flagsDecoder flags of
        Ok decodedFlags ->
            decodedFlags

        Err _ ->
            defaultFlags


view : Model -> Document Msg
view model =
    { title = "Boardr"
    , body = viewBody model
    }


viewBody : Model -> List (Html Msg)
viewBody model =
    [ viewNavbar model
    , div [ class "container-fluid" ]
        (case model.location.route of
            HomeRoute ->
                [ Html.map HomePage (lazy HomePage.view (HomePage.viewModel model)) ]

            GameRoute id ->
                List.map (Html.map GamePage) (GamePage.view (GamePage.viewModel id model))

            LoginRoute ->
                List.map (Html.map LoginPage) LoginPage.view

            RegisterRoute ->
                [ Html.map RegisterPage RegisterPage.view ]

            StatsRoute ->
                [ Html.map StatsPage (StatsPage.view model.ui.stats) ]

            NotFound ->
                [ p [] [ text "Page not found" ] ]
        )
    ]


viewNavbar : Model -> Html Msg
viewNavbar model =
    nav [ class "navbar fixed-top navbar-dark bg-dark" ]
        [ a [ class "navbar-brand", href "/" ]
            [ text "Boardr"
            ]
        , case model.session of
            Nothing ->
                div [ class "btn-group" ]
                    [ a [ class "btn btn-secondary navbar-btn", href "/login" ]
                        [ text "Log in"
                        ]
                    , a [ class "btn btn-secondary navbar-btn", href "/register" ]
                        [ text "Register"
                        ]
                    ]

            Just auth ->
                div []
                    [ span [ class "navbar-text mr-3" ] [ text auth.user.name ]
                    , div [ class "btn-group" ]
                        [ a [ class "btn btn-info navbar-btn", href "/stats" ]
                            [ text "Stats"
                            ]
                        , a [ class "btn btn-secondary navbar-btn", onClick LogOut ]
                            [ text "Log out"
                            ]
                        ]
                    ]
        ]
