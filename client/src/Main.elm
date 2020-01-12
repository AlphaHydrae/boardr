module Main exposing (main)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--

import Browser
import Html exposing (Html, p, text)

main : Program () Model Never
main =
  Browser.sandbox { init = init, update = update, view = view }

type alias Model = Int

init : Model
init =
  0

update : Never -> Model -> Model
update _ model =
  model

view : Model -> Html Never
view _ =
  p [] [ text "Hello World" ]