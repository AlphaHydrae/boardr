defmodule Boardr.Rules.TicTacToe do
  alias Boardr.{Position,Rules}
  require Boardr.Rules
  require Position

  defmodule State do
    defstruct board: nil,
              last_player_number: nil,
              last_position: nil

    @type t :: %Boardr.Rules.TicTacToe.State{
      board: List.t,
      last_player_number: Integer.t,
      last_position: Position.d2
    }
  end

  def board(Rules.game(), nil) do
    {:ok, []}
  end

  def board(Rules.game(), %State{board: board}) do
    {
      :ok,
      Range.new(0, tuple_size(board) - 1)
      |> Enum.reduce([], fn i, acc ->
        value = elem(board, i)
        cond do
          is_nil(value) -> acc
          true -> [ %{position: [rem(i, 3), div(i, 3)], player: value} | acc ]
        end
      end)
    }
  end

  def play(
    Rules.action(type: :take, player_number: player_number, position: Position.d2()) = action,
    Rules.game(players: [Rules.player(number: first_player_number), _]) = game,
    nil
  ) when player_number === first_player_number do
    play_and_get_state action, game, %State{board: initial_board()}
  end

  def play(
    Rules.action(position: Position.d2(col: col, row: row)),
    Rules.game(),
    %State{board: board}
  ) when is_nil(elem(board, row * 3 + col)) do
    {:error, :position_already_taken}
  end

  def play(
    Rules.action(type: :take, player_number: player_number) = action,
    Rules.game(players: players) = game,
    %State{last_player_number: last_player_number} = state
  ) do
    cond do
      next_player_number(last_player_number, players) === player_number ->
        play_and_get_state action, game, state
      true ->
        {:error, :wrong_turn}
    end
  end

  def play(_, _, _) do
    {:error, :invalid_action}
  end

  def possible_actions(Rules.game(players: [Rules.player(number: first_player_number) | _]), nil) do
    board = initial_board()
    {
      :ok,
      Range.new(0, tuple_size(board) - 1)
      |> Enum.reduce([], fn i, acc ->
        value = elem(board, i)
        cond do
          is_nil(value) -> [ Rules.action(type: :take, player_number: first_player_number, position: Position.d2(col: rem(i, 3), row: div(i, 3))) | acc ]
          true -> acc
        end
      end)
    }
  end

  def possible_actions(Rules.game(players: players), %State{board: board, last_player_number: last_player_number}) do
    player_number = next_player_number(last_player_number, players)
    {
      :ok,
      Range.new(0, tuple_size(board) - 1)
      |> Enum.reduce([], fn i, acc ->
        value = elem(board, i)
        cond do
          is_nil(value) -> [ Rules.action(type: :take, player_number: player_number, position: Position.d2(col: rem(i, 3), row: div(i, 3))) | acc ]
          true -> acc
        end
      end)
    }
  end

  defp update_board(board, Position.d2(col: col, row: row), value) when is_tuple(board) and is_integer(value) do
    put_elem(board, row * 3 + col, value)
  end

  defp initial_board() do
    {nil, nil, nil, nil, nil, nil, nil, nil, nil}
  end

  defp next_player_number(last_player_number, players) when is_integer(last_player_number) and is_list(players) do
    next_player_number last_player_number, players, nil
  end

  defp next_player_number(last_player_number, [Rules.player(number: first_player_number) | _], nil) when is_integer(last_player_number) and last_player_number < first_player_number do
    first_player_number
  end

  defp next_player_number(last_player_number, [Rules.player(number: first_player_number) | other_players], nil) when is_integer(last_player_number) do
    next_player_number(last_player_number, other_players, first_player_number)
  end

  defp next_player_number(last_player_number, [Rules.player(number: player_number) | _], first_player_number) when is_integer(last_player_number) and is_integer(first_player_number) and last_player_number < player_number do
    player_number
  end

  defp next_player_number(last_player_number, [Rules.player(number: player_number) | _], first_player_number) when is_integer(last_player_number) and is_integer(first_player_number) and last_player_number === player_number do
    first_player_number
  end

  defp play_and_get_state(
    Rules.action(player_number: player_number, position: Position.d2(col: action_col, row: action_row) = position) = action,
    Rules.game(),
    %State{board: board} = state
  ) do

    new_board = update_board(board, position, player_number)

    win =
      0..2 |> Enum.all?(fn col -> col === action_col or elem(board, action_row * 3 + col) === player_number end) or
      0..2 |> Enum.all?(fn row -> row === action_row or elem(board, row * 3 + action_col) === player_number end) or
      0..2 |> Enum.all?(fn i -> i === action_col and i === action_row or elem(board, i * 3 + i) === player_number end) or
      0..2 |> Enum.all?(fn i -> i === action_col and 2 - i === action_row or elem(board, (2 - i) * 3 + i) === player_number end)

    new_state = %State{state | board: new_board, last_player_number: player_number, last_position: position}

    # TODO: draw
    if win do
      {:ok, action, new_state, {:win, [player_number]}}
    else
      {:ok, action, new_state, :playing}
    end
  end
end
