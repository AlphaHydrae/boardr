defmodule Boardr.Gaming.GameServer.State do
  defstruct game: nil,
            rules_state: nil

  @type t :: %Boardr.Gaming.GameServer.State{
    game: Boardr.Game.t,
    rules_state: Map.t
  }
end
