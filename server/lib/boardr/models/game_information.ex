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

  alias Boardr.Game
  alias Boardr.Rules.TicTacToe, as: Rules

  # FIXME: remove
  def for_game(%Game{actions: actions, players: players, settings: settings}) when is_list(actions) and is_list(players) do
    initial_game_info = %__MODULE__{
      players: players,
      settings: settings
    }

    {:board, initial_board_data} = Rules.board initial_game_info, nil, nil
    board_data = Enum.reduce actions, initial_board_data, fn action, current_board_data ->
      {:board, new_board_data} = Rules.board initial_game_info, current_board_data, action
      new_board_data
    end

    %__MODULE__{
      initial_game_info |
      board: board_data,
      last_action: List.last(actions)
    }
  end
end
