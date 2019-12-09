defmodule Boardr.PossibleMove do
  defstruct data: [],
            game: nil,
            player: nil,
            type: nil

  @type t :: %Boardr.PossibleMove{
    data: List.t,
    game: Boardr.Game.t,
    player: Boardr.Player.t,
    type: Atom.t
  }
end
