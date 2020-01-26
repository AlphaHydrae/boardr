module Store.Init exposing (init)

import Browser.Navigation as Nav
import Dict
import Flags exposing (Flags)
import Pages.Home.Page as HomePage
import Routes exposing (Route, toRoute)
import Store.Model exposing (BusinessDataModel, LocationModel, Model, UiModel)
import Url exposing (Url)


init : Flags -> Url -> Nav.Key -> Model
init flags url key =
    Model initBusinessDataModel flags (initLocationModel key url (toRoute url)) (initUiModel flags)


initBusinessDataModel : BusinessDataModel
initBusinessDataModel =
    BusinessDataModel Dict.empty


initLocationModel : Nav.Key -> Url -> Route -> LocationModel
initLocationModel key url route =
    LocationModel key url (toRoute url)


initUiModel : Flags -> UiModel
initUiModel flags =
    { home = HomePage.init flags }