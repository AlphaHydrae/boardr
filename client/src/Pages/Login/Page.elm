module Pages.Login.Page exposing (init, store, view)

import Flags exposing (Flags)
import Html exposing (Html, button, form, h2, input, label, text)
import Html.Attributes exposing (for, type_)
import Html.Events exposing (onInput, onSubmit)
import Pages.Login.Model exposing (Model)
import Pages.Login.Msg exposing (Msg(..))
import Store.Model exposing (UiModel)


init : Flags -> Model
init _ =
    ""


store : UiModel -> Msg -> UiModel
store ui msg =
    { ui | login = update msg ui.login }


update : Msg -> Model -> Model
update msg model =
    case msg of
        EditLoginEmail value ->
            value

        SubmitLoginForm ->
            model


view : List (Html Msg)
view =
    [ h2 [] [ text "Log in" ]
    , form [ onSubmit SubmitLoginForm ]
        [ label [ for "login-email" ] [ text "Email" ]
        , input [ type_ "text", onInput EditLoginEmail ] []
        , button [ type_ "submit" ] [ text "Submit" ]
        ]
    ]
