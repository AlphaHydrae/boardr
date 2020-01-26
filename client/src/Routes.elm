module Routes exposing (Route (..), toRoute)

import Url exposing (Url)
import Url.Parser as UrlParser


type Route
    = HomeRoute
    | StatsRoute
    | NotFound


routes : UrlParser.Parser (Route -> a) a
routes =
    UrlParser.oneOf
        [ UrlParser.map HomeRoute UrlParser.top
        , UrlParser.map StatsRoute (UrlParser.s "stats")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (UrlParser.parse routes url)