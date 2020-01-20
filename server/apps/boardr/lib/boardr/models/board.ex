defmodule Boardr.Board do
  defstruct data: [],
            dimensions: [],
            game_id: nil

  @type t :: %Boardr.Board{
    data: List.t,
    dimensions: [integer()],
    game_id: binary
  }
end
