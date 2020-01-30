module Store.Model exposing (DataModel, LocationModel, Model, SessionModel, UiModel)

import Api exposing (ApiGame, ApiIdentity, ApiRoot, ApiUser)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Flags exposing (Flags)
import Pages.Home.Model as HomePage
import Pages.Register.Model as RegisterPage
import Routes exposing (Route)
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


type alias SessionModel =
    { token : Maybe String
    , user : Maybe ApiUser
    }


type alias UiModel =
    { home : HomePage.Model
    , register : RegisterPage.Model
    }
