module Pages.Register.Msg exposing (Msg(..))


type Msg
    = EditRegisterEmail String
    | EditRegisterUsername String
    | SubmitRegisterForm
