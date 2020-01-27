module Store.Init exposing (init)

import Api exposing (ApiGame)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Flags exposing (Flags)
import Pages.Home.Page as HomePage
import Routes exposing (toRoute)
import Store.Model exposing (LocationModel, Model, UiModel)
import Url exposing (Url)


init : Flags -> Url -> Nav.Key -> Model
init flags url key =
    Model (initBusinessData flags) flags (initLocationModel key url) (initUiModel flags)


initBusinessData : Flags -> Dict String ApiGame
initBusinessData _ =
    Dict.empty


initLocationModel : Nav.Key -> Url -> LocationModel
initLocationModel key url =
    LocationModel key url (toRoute url)


initUiModel : Flags -> UiModel
initUiModel flags =
    HomePage.init flags