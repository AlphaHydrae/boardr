defmodule Boardr.Board do
  defstruct data: [],
            dimensions: [],
            game: nil

  @type t :: %Boardr.Board{
    data: List.t,
    dimensions: [integer()],
    game: Boardr.Game.t
  }

  alias Boardr.Game
  alias Boardr.Rules.TicTacToe, as: Rules

  def board(%Game{actions: actions} = game) when is_list(actions) do
    {:board, initial_board_data} = Rules.board game, nil, nil
    Enum.reduce actions, initial_board_data, fn action, current_board_data ->
      {:board, new_board_data} = Rules.board game, current_board_data, action
      new_board_data
    end
  end
end
