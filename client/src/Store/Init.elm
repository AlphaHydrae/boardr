module Store.Init exposing (init)

import Browser.Navigation as Nav
import Dict
import Flags exposing (Flags)
import Pages.Game.Page as GamePage
import Pages.Home.Page as HomePage
import Pages.Login.Page as LoginPage
import Pages.Register.Page as RegisterPage
import Routes exposing (toRoute)
import Store.Model exposing (DataModel, LocationModel, Model, UiModel)
import Store.Session exposing (SessionModel)
import Url exposing (Url)


init : Flags -> Url -> Nav.Key -> Model
init flags url key =
    Model (initDataModel flags) flags (initLocationModel key url) (initSessionModel flags) (initUiModel flags)


initDataModel : Flags -> DataModel
initDataModel _ =
    { games = Dict.empty
    , identities = Dict.empty
    , players = Dict.empty
    , root = Nothing
    }


initLocationModel : Nav.Key -> Url -> LocationModel
initLocationModel key url =
    LocationModel key url (toRoute url)


initSessionModel : Flags -> SessionModel
initSessionModel flags =
    flags.session


initUiModel : Flags -> UiModel
initUiModel flags =
    { game = GamePage.init flags
    , home = HomePage.init flags
    , login = LoginPage.init flags
    , register = RegisterPage.init flags
    }
