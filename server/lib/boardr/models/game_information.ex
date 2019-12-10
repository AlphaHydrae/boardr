defmodule Boardr.GameInformation do
  defstruct board: nil,
            data: %{},
            last_action: nil,
            players: [],
            possible_actions: [],
            settings: %{}

  @type t :: %Boardr.GameInformation{
    board: List.t,
    data: Map.t,
    last_action: Boardr.Action.t,
    players: [Boardr.Player.t],
    possible_actions: [Boardr.PossibleAction.t],
    settings: Map.t
  }
end
