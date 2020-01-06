defmodule Boardr.Board do
  defstruct data: [],
            dimensions: [],
            game: nil

  @type t :: %Boardr.Board{
    data: List.t,
    dimensions: [integer()],
    game: Boardr.Game.t
  }
end
