module Pages.Register.Page exposing (init, store, view)

import Flags exposing (Flags)
import Html exposing (Html, button, div, form, input, label, text)
import Html.Attributes exposing (class, for, type_)
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
    div [ class "col-12 col-md-4 offset-md-4" ]
        [ form [ onSubmit SubmitRegisterForm ]
            [ div [ class "form-group" ]
                [ label [ for "register-email" ] [ text "Email" ]
                , input [ class "form-control", type_ "text", onInput EditRegisterEmail ] []
                ]
            , div [ class "form-group" ]
                [ label [ for "register-name" ] [ text "Username" ]
                , input [ class "form-control", type_ "text", onInput EditRegisterUsername ] []
                ]
            , button [ class "btn btn-block btn-primary", type_ "submit" ] [ text "Submit" ]
            ]
        ]
