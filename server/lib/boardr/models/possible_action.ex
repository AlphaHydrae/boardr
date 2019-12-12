defmodule Boardr.PossibleAction do
  defstruct game: nil,
            player: nil,
            position: nil,
            type: nil

  @type t :: %Boardr.PossibleAction{
    game: Boardr.Game.t,
    player: Boardr.Player.t,
    position: Integer.t,
    type: Atom.t
  }
end
