defmodule Boardr.Rules.TicTacToe do
  alias Boardr.{Game,GameInformation,Move,Player,PossibleMove}

  defguard is_board_coordinate(value) when is_integer(value) and value >= 0 and value <= 3

  def init_game_data(_) do
    %{}
  end

  def possible_moves(%GameInformation{board: nil} = info) do
    possible_moves %GameInformation{
      info |
      board: initial_board()
    }
  end

  def possible_moves(
    %GameInformation{
      board: board,
      last_move: nil,
      players: players
    }
  ) do
    current_player = List.first players

    board
    |> Enum.with_index()
    |> Enum.reduce([], fn {row, row_index}, acc ->
      acc ++ (row
      |> Enum.with_index()
      |> Enum.reduce([], fn {value, col_index}, col_acc ->
        if value === nil, do: [[col_index, row_index] | col_acc], else: col_acc
      end))
    end)
    |> Enum.map(fn position ->
      %PossibleMove{
        data: position,
        player: current_player,
        type: :take
      }
    end)
  end

  def possible_moves(
    %GameInformation{
      board: board,
      last_move: %Move{player: %Player{number: last_player_number}} = last_move,
      players: players
    }
  ) do
    current_player = next_player last_move, players

    board
    |> Enum.with_index()
    |> Enum.reduce([], fn {row, row_index}, acc ->
      acc ++ (row
      |> Enum.with_index()
      |> Enum.reduce([], fn {value, col_index}, col_acc ->
        if value === nil, do: [[col_index, row_index] | col_acc], else: col_acc
      end))
    end)
    |> Enum.map(fn position ->
      %PossibleMove{
        data: position,
        player: current_player,
        type: :take
      }
    end)
  end

  def play(
    %GameInformation{board: board, last_move: nil, players: [%Player{number: first_number} | _]},
    %Player{number: player_number} = player,
    %{"data" => [col, row], "type" => "take"}
  ) when is_list(board) and player_number === first_number and is_board_coordinate(col) and is_board_coordinate(row) do
    {
      :ok,
      %Move{
        data: [col, row],
        player: player,
        type: "take"
      }
    }
  end

  def play(%GameInformation{}, %Player{}, _) do
    {:error, :invalid_move}
  end

  def board(%Game{}, nil, nil) do
    {:board, initial_board()}
  end

  def board(%Game{}, board, %Move{data: [col, row], player: %Player{number: player_number}}) when is_list(board) and is_board_coordinate(col) and is_board_coordinate(row) do
    {:board, board_with_value(board, [col, row], player_number)}
  end

  defp board_with_value([], [_col, _row], _) do
    :board_row_out_of_bounds
  end

  defp board_with_value([ headRow | tailRows ], [col, 0], value) do
    [ row_with_value(headRow, col, value) | tailRows ]
  end

  defp board_with_value([ headCol | tailCols ], [col, row], value) do
    [ headCol | board_with_value(tailCols, [col, row - 1], value) ]
  end

  defp initial_board() do
    [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
  end

  defp next_player(%Move{} = move, players) when is_list(players) do
    next_player move, players, nil
  end

  defp next_player(%Move{player: %Player{number: last_player_number}} = move, [%Player{number: first_player_number} = first_player | other_players], nil) do
    cond do
      last_player_number < first_player_number -> first_player_number
      last_player_number >= first_player_number -> next_player(move, other_players, first_player)
    end
  end

  defp next_player(%Move{player: %Player{number: last_player_number}}, [%Player{number: player_number} = player | _], %Player{} = first_player) do
    cond do
      last_player_number < player_number -> player
      last_player_number === player_number -> first_player
    end
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
