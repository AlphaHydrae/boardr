module Routes exposing (Route(..), toRoute)

import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>), map, oneOf, s, string, top)


type Route
    = HomeRoute
    | GameRoute String
    | LoginRoute
    | RegisterRoute
    | StatsRoute
    | NotFound


routes : UrlParser.Parser (Route -> a) a
routes =
    oneOf
        [ map HomeRoute top
        , map GameRoute (s "games" </> string)
        , map LoginRoute (s "login")
        , map RegisterRoute (s "register")
        , map StatsRoute (s "stats")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (UrlParser.parse routes url)
