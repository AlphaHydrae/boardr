module Main exposing (main)

import Api exposing (apiRootDecoder)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Flags exposing (defaultFlags, Flags, flagsDecoder, ProgramFlags)
import Html exposing (Html, p, text)
import Html.Lazy exposing (lazy)
import Http
import Json.Decode as Decode
import Store.Init
import Store.Model exposing (Model)
import Store.Msg exposing (Msg(..))
import Store.Update exposing (update)
import Pages.Game.Page as GamePage
import Pages.Home.Page as HomePage
import Routes exposing (Route (..))
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
    , Http.get
        { url = flags
        , expect = Http.expectJson ApiRootRetrieved apiRootDecoder
        }
    )


parseProgramFlags : Decode.Value -> Flags
parseProgramFlags flags =
    case Decode.decodeValue flagsDecoder flags of
        Ok decodedFlags ->
            decodedFlags

        Err _ ->
            defaultFlags


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none


view : Model -> Document msg
view model =
    { title = "Boardr"
    , body = [ viewBody model ]
    }


viewBody : Model -> Html msg
viewBody model =
    case model.location.route of
        HomeRoute ->
            lazy HomePage.view (HomePage.viewModel model)

        GameRoute id ->
            lazy GamePage.view (GamePage.viewModel id model)

        StatsRoute ->
            p [] [ text "Stats" ]

        NotFound ->
            p [] [ text "Page not found" ]
