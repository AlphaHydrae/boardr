module Store.Model exposing (BusinessDataModel, LocationModel, Model, UiModel)

import Browser.Navigation as Nav
import Dict exposing (Dict)
import Flags exposing (Flags)
import Pages.Home.Model as HomePage
import Routes exposing (Route)
import Url exposing (Url)
import Utils.Api exposing (ApiGame)


type alias BusinessDataModel =
    { games : Dict String ApiGame }


type alias LocationModel =
    { key : Nav.Key
    , url : Url
    , route : Route
    }


type alias UiModel =
    { home : HomePage.Model }


type alias Model =
    { data : BusinessDataModel
    , flags : Flags
    , location : LocationModel
    , ui : UiModel
    }
