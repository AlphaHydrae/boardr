module Main exposing (main)

import Api.Req exposing (retrieveRoot)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Flags exposing (Flags, ProgramFlags, defaultFlags, flagsDecoder)
import Html exposing (Html, p, text)
import Html.Lazy exposing (lazy)
import Json.Decode as Decode
import Pages.Game.Page as GamePage
import Pages.Home.Page as HomePage
import Pages.Login.Page as LoginPage
import Pages.Register.Page as RegisterPage
import Routes exposing (Route(..))
import Store.Init
import Store.Model exposing (Model)
import Store.Msg exposing (Msg(..))
import Store.Sub exposing (subscriptions)
import Store.Update exposing (update)
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
    , retrieveRoot flags.apiUrl
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
    case model.location.route of
        HomeRoute ->
            [ Html.map HomePage (lazy HomePage.view (HomePage.viewModel model)) ]

        GameRoute id ->
            [ lazy GamePage.view (GamePage.viewModel id model) ]

        LoginRoute ->
            List.map (Html.map LoginPage) LoginPage.view

        RegisterRoute ->
            [ Html.map RegisterPage RegisterPage.view ]

        StatsRoute ->
            [ p [] [ text "Stats" ] ]

        NotFound ->
            [ p [] [ text "Page not found" ] ]
