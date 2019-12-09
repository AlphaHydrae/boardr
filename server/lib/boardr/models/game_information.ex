defmodule Boardr.GameInformation do
  defstruct board: nil,
            data: %{},
            last_move: nil,
            players: [],
            possible_moves: [],
            settings: %{}

  @type t :: %Boardr.GameInformation{
    board: List.t,
    data: Map.t,
    last_move: Boardr.Move.t,
    players: [Boardr.Player.t],
    possible_moves: [Boardr.PossibleMove.t],
    settings: Map.t
  }
end
