defmodule Boardr.PossibleAction do
  defstruct data: [],
            game: nil,
            player: nil,
            type: nil

  @type t :: %Boardr.PossibleAction{
    data: List.t,
    game: Boardr.Game.t,
    player: Boardr.Player.t,
    type: Atom.t
  }
end
