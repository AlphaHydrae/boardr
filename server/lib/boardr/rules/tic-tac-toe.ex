defmodule Boardr.Rules.TicTacToe do
  alias Boardr.{Action,GameInformation,Player,Position,PossibleAction}

  require Position

  defguard is_board_coordinate(value) when is_integer(value) and value >= 0 and value <= 3

  def possible_actions(%GameInformation{board: nil} = info) do
    possible_actions %GameInformation{
      info |
      board: initial_board()
    }
  end

  def possible_actions(
    %GameInformation{
      last_action: nil,
      players: players
    } = game_info
  ) do
    possible_actions_for game_info, List.first(players)
  end

  def possible_actions(
    %GameInformation{
      last_action: last_action,
      players: players
    } = game_info
  ) do
    possible_actions_for game_info, next_player(last_action, players)
  end

  def play(
    %GameInformation{board: board, last_action: nil, players: [%Player{number: first_number} | _]} = game_info,
    %Player{number: player_number} = player,
    %{"position" => [col, row], "type" => "take"}
  ) when is_list(board) and player_number === first_number and is_board_coordinate(col) and is_board_coordinate(row) do
    play_and_get_state game_info, %Action{
      player: player,
      position: Position.dump(col, row),
      type: "take"
    }
  end

  def play(
    %GameInformation{last_action: last_action, players: players} = game_info,
    %Player{number: player_number} = player,
    %{"position" => [col, row], "type" => "take"}
  ) when is_board_coordinate(col) and is_board_coordinate(row) do
    current_player = next_player last_action, players
    cond do
      current_player.number === player_number ->
        play_and_get_state game_info, %Action{
          player: player,
          position: Position.dump(col, row),
          type: "take"
        }
      true ->
        {:error, :invalid_action}
    end
  end

  def play(%GameInformation{}, %Player{}, _) do
    {:error, :invalid_action}
  end

  def board(%GameInformation{}, nil, nil) do
    {:board, initial_board()}
  end

  def board(%GameInformation{}, board, %Action{player: %Player{number: player_number}, position: position}) when is_list(board) and is_integer(position) and position >= 0 do
    {:board, board_with_value(board, Position.parse(position), player_number)}
  end

  defp board_with_value([], {Position, _col, _row}, _) do
    :board_row_out_of_bounds
  end

  defp board_with_value([ headRow | tailRows ], {Position, col, 0}, value) do
    [ row_with_value(headRow, col, value) | tailRows ]
  end

  defp board_with_value([ headCol | tailCols ], {Position, col, row}, value) do
    [ headCol | board_with_value(tailCols, Position.d2(col: col, row: row - 1), value) ]
  end

  defp initial_board() do
    [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
  end

  defp next_player(%Action{} = action, players) when is_list(players) do
    next_player action, players, nil
  end

  defp next_player(%Action{player: %Player{number: last_player_number}} = action, [%Player{number: first_player_number} = first_player | other_players], nil) do
    cond do
      last_player_number < first_player_number -> first_player_number
      last_player_number >= first_player_number -> next_player(action, other_players, first_player)
    end
  end

  defp next_player(%Action{player: %Player{number: last_player_number}}, [%Player{number: player_number} = player | _], %Player{} = first_player) do
    cond do
      last_player_number < player_number -> player
      last_player_number === player_number -> first_player
    end
  end

  defp play_and_get_state(
    %GameInformation{} = game_info,
    %Action{
      player: %Player{number: player_number} = player,
      position: position
    } = action
  ) when is_integer(position) and position >= 0 do
    {Position, col, row} = Position.parse(position)
    {:board, new_board} = board(game_info, game_info.board, action)

    rows_count = length(new_board)
    win =
      new_board |> Enum.at(row) |> Enum.all?(fn value -> value === player_number end) or
      new_board |> Enum.map(fn current_row -> Enum.at(current_row, col) end) |> Enum.all?(fn value -> value === player_number end) or
      0..(rows_count - 1) |> Enum.all?(fn row -> new_board |> Enum.at(row) |> Enum.at(row) === player_number end) or
      (rows_count - 1)..0 |> Enum.all?(fn row -> new_board |> Enum.at(row) |> Enum.at(rows_count - 1 - row) === player_number end)

    if win do
      {:ok, action, :win, [player]}
    else
      {:ok, action, :playing, []}
    end
  end

  defp possible_actions_for(%GameInformation{board: board}, %Player{} = player) do
    board
    |> Enum.with_index()
    |> Enum.reduce([], fn {row, row_index}, acc ->
      acc ++ (row
      |> Enum.with_index()
      |> Enum.reduce([], fn {value, col_index}, col_acc ->
        if value === nil, do: [Position.d2(col: col_index, row: row_index) | col_acc], else: col_acc
      end))
    end)
    |> Enum.map(fn position ->
      %PossibleAction{
        player: player,
        position: Position.dump(position),
        type: :take
      }
    end)
  end

  defp row_with_value([], _, _) do
    :board_column_out_of_bounds
  end

  defp row_with_value([ _headCell | tailCells ], 0, value) do
    [ value | tailCells ]
  end

  defp row_with_value([ headCell | tailCells ], col, value) do
    [ headCell | row_with_value(tailCells, col - 1, value) ]
  end
end
