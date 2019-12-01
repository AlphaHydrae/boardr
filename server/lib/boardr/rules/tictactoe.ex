defmodule Boardr.Rules.Tictactoe do
  defguard is_board_coordinate(value) when is_integer(value) and value >= 0 and value <= 3

  def init_board(_) do
    [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
  end

  def init_game_data(_) do
    %{}
  end

  def play_move(_state, {_player, [col, row]}) when is_board_coordinate(col) and is_board_coordinate(row) do
    {:move, [col, row]}
  end

  def update_board(state, board, {player, [col, row]}) when is_board_coordinate(col) and is_board_coordinate(row) do
    player_index = Enum.find_index(state.players, fn p -> p === player end)
    set_board_value(board, [col, row], player_index)
  end

  defp set_board_value([], [_col, _row], _) do
    :board_row_out_of_bounds
  end

  defp set_board_value([ headRow | tailRows ], [col, 0], value) do
    [ set_row_value(headRow, col, value) | tailRows ]
  end

  defp set_board_value([ headCol | tailCols ], [col, row], value) do
    [ headCol | set_board_value(tailCols, [col, row - 1], value) ]
  end

  defp set_row_value([], _, _) do
    :board_column_out_of_bounds
  end

  defp set_row_value([ _headCell | tailCells ], 0, value) do
    [ value | tailCells ]
  end

  defp set_row_value([ headCell | tailCells ], col, value) do
    [ headCell | set_row_value(tailCells, col - 1, value) ]
  end
end
