module Pages.Register.Page exposing (init, store, view)

import Flags exposing (Flags)
import Html exposing (Html, button, div, form, h2, input, label, text)
import Html.Attributes exposing (for, type_)
import Html.Events exposing (onInput, onSubmit)
import Pages.Register.Model exposing (Model)
import Pages.Register.Msg exposing (Msg(..))
import Store.Model exposing (UiModel)


init : Flags -> Model
init _ =
    { email = ""
    , name = ""
    }


store : UiModel -> Msg -> UiModel
store model msg =
    { model | register = update msg model.register }


update : Msg -> Model -> Model
update msg model =
    case msg of
        EditRegisterEmail value ->
            { model | email = value }

        EditRegisterUsername value ->
            { model | name = value }

        SubmitRegisterForm ->
            model


view : Html Msg
view =
    div []
        [ h2 [] [ text "Register" ]
        , form [ onSubmit SubmitRegisterForm ]
            [ label [ for "register-email" ] [ text "Email" ]
            , input [ type_ "text", onInput EditRegisterEmail ] []
            , label [ for "register-name" ] [ text "Username" ]
            , input [ type_ "text", onInput EditRegisterUsername ] []
            , button [ type_ "submit" ] [ text "Submit" ]
            ]
        ]
