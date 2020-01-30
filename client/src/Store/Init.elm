module Store.Init exposing (init)

import Browser.Navigation as Nav
import Dict
import Flags exposing (Flags)
import Pages.Home.Page as HomePage
import Pages.Register.Page as RegisterPage
import Routes exposing (toRoute)
import Store.Model exposing (DataModel, LocationModel, Model, SessionModel, UiModel)
import Url exposing (Url)


init : Flags -> Url -> Nav.Key -> Model
init flags url key =
    Model (initDataModel flags) flags (initLocationModel key url) (initSessionModel flags) (initUiModel flags)


initDataModel : Flags -> DataModel
initDataModel _ =
    { games = Dict.empty
    , identities = Dict.empty
    , root = Nothing
    }


initLocationModel : Nav.Key -> Url -> LocationModel
initLocationModel key url =
    LocationModel key url (toRoute url)


initSessionModel : Flags -> SessionModel
initSessionModel _ =
    SessionModel Nothing Nothing


initUiModel : Flags -> UiModel
initUiModel flags =
    { home = HomePage.init flags
    , register = RegisterPage.init flags
    }
