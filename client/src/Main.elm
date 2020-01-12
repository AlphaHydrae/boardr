module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (Html, p, text)
import Html.Lazy exposing (lazy)
import Json.Decode
import Url
import Url.Parser exposing (Parser, map, oneOf, parse, s, top)

import Pages.Home as HomePage


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = RequestUrl
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Flags =
    Json.Decode.Value


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    }


type Msg
    = RequestUrl Browser.UrlRequest
    | UrlChanged Url.Url


type Route
    = HomeRoute
    | StatsRoute
    | NotFound


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model key url (toRoute url), Cmd.none )


routes : Parser (Route -> a) a
routes =
    oneOf
        [ map HomeRoute top
        , map StatsRoute (s "stats")
        ]


toRoute : Url.Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse routes url)


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RequestUrl urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url, route = toRoute url }
            , Cmd.none
            )


view : Model -> Document msg
view model =
    { title = ""
    , body = [ body model ]
    }


body : Model -> Html msg
body model =
    case model.route of
        HomeRoute ->
            lazy HomePage.page 0

        StatsRoute ->
            p [] [ text "Stats" ]

        NotFound ->
            p [] [ text "Page not found" ]
