module Store.Model exposing (LocationModel, Model, UiModel)

import Api exposing (ApiGame)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Flags exposing (Flags)
import Pages.Home.Model as HomePage
import Routes exposing (Route)
import Url exposing (Url)


type alias LocationModel =
    { key : Nav.Key
    , url : Url
    , route : Route
    }


type alias UiModel = HomePage.Model


type alias Model =
    { data : Dict String ApiGame
    , flags : Flags
    , location : LocationModel
    , ui : UiModel
    }
