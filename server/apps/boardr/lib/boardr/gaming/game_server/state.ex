# FIXME: use a record
defmodule Boardr.Gaming.GameServer.State do
  defstruct [:game, :rules, :rules_game, :rules_state]

  @type t :: %Boardr.Gaming.GameServer.State{
    game: Boardr.Game.t,
    rules: Boardr.Rules.t,
    rules_game: Domain.game,
    rules_state: Map.t
  }
end
