module Pages.Stats.Model exposing (Model)

import Api.Model exposing (ApiStats)
import Types exposing (RemoteData)


type alias Model = RemoteData ApiStats
