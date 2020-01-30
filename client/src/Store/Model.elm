module Store.Model exposing (DataModel, LocationModel, Model, UiModel)

import Api.Model exposing (ApiGame, ApiIdentity, ApiRoot)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Flags exposing (Flags)
import Pages.Home.Model as HomePage
import Pages.Login.Model as LoginPage
import Pages.Register.Model as RegisterPage
import Routes exposing (Route)
import Store.Session exposing (SessionModel)
import Url exposing (Url)


type alias DataModel =
    { games : Dict String ApiGame
    , identities : Dict String ApiIdentity
    , root : Maybe ApiRoot
    }


type alias LocationModel =
    { key : Nav.Key
    , url : Url
    , route : Route
    }


type alias Model =
    { data : DataModel
    , flags : Flags
    , location : LocationModel
    , session : SessionModel
    , ui : UiModel
    }


type alias UiModel =
    { home : HomePage.Model
    , login : LoginPage.Model
    , register : RegisterPage.Model
    }
