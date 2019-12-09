defmodule Boardr.Board do
  defstruct data: [],
            game: nil

  @type t :: %Boardr.Board{
    data: List.t,
    game: Boardr.Game.t
  }

  alias Boardr.Game
  alias Boardr.Rules.TicTacToe, as: Rules

  def board(%Game{moves: moves} = game) when is_list(moves) do
    {:board, initial_board_data} = Rules.board game, nil, nil
    Enum.reduce moves, initial_board_data, fn move, current_board_data ->
      {:board, new_board_data} = Rules.board game, current_board_data, move
      new_board_data
    end
  end
end
