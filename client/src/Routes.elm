module Routes exposing (Route (..), toRoute)

import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>), map, oneOf, s, string, top)


type Route
    = HomeRoute
    | GameRoute String
    | StatsRoute
    | NotFound


routes : UrlParser.Parser (Route -> a) a
routes =
    oneOf
        [ map HomeRoute top
        , map GameRoute (s "games" </> string)
        , map StatsRoute (s "stats")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (UrlParser.parse routes url)