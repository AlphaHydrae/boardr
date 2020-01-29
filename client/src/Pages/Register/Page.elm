module Pages.Register.Page exposing (init, updateUi, view)

import Flags exposing (Flags)
import Html exposing (Html, div, form, h2, input, label, p, text)
import Html.Attributes exposing (for, type_)
import Html.Events exposing (onInput, onSubmit)
import Pages.Register.Model exposing (Model)
import Store.Model exposing (UiModel)
import Store.Msg exposing (Msg(..))


init : Flags -> Model
init _ =
    { email = "" }


update : Msg -> Model -> Model
update msg model =
    case msg of
        EditRegisterEmail value ->
            { model | email = value }
        SubmitRegisterForm ->
            model
        _ ->
            model


updateUi : Msg -> UiModel -> UiModel
updateUi msg model =
    { model | register = update msg model.register }


view : Html Msg
view =
    div []
        [ h2 [] [ text "Register" ]
        , form [ onSubmit SubmitRegisterForm ]
            [ label [ for "register-email" ] [ text "Email" ]
            , input [ type_ "text", onInput EditRegisterEmail ] []
            ]
        ]
