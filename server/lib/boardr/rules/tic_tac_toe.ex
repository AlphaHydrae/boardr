defmodule Boardr.Rules.TicTacToe do
  alias Boardr.Rules.Domain

  import Boardr.Rules.Domain, only: [is_player_number: 1]

  require Boardr.Rules.Domain

  @behaviour Boardr.Rules

  # TODO: use a record, drop last player number
  defmodule State do
    defstruct board: nil,
              last_player_number: nil,
              last_position: nil

    @type t :: %Boardr.Rules.TicTacToe.State{
            board: List.t(),
            last_player_number: Integer.t(),
            last_position: Domain.d2()
          }
  end

  @impl true
  def board(Domain.game(), nil) do
    {:ok, []}
  end

  @impl true
  def board(Domain.game(), %State{board: board}) do
    {
      :ok,
      Range.new(0, tuple_size(board) - 1)
      |> Enum.reduce([], fn i, acc ->
        value = elem(board, i)

        cond do
          is_nil(value) -> acc
          true -> [%{position: [rem(i, 3), div(i, 3)], player: value} | acc]
        end
      end)
    }
  end

  @impl true
  def play(_action, Domain.game(state: :draw), _state) do
    {:error, :game_finished}
  end

  @impl true
  def play(_action, Domain.game(state: :win), _state) do
    {:error, :game_finished}
  end

  @impl true
  def play(
        Domain.take(player_number: player_number),
        Domain.game(players: [Domain.player(number: first_player_number), _]),
        nil
      )
      when player_number !== first_player_number do
    {:error, :wrong_turn}
  end

  @impl true
  def play(
        Domain.take(player_number: player_number, position: Domain.d2()) = action,
        Domain.game(players: [Domain.player(number: first_player_number), _]) = game,
        nil
      )
      when player_number === first_player_number do
    play_and_get_state(action, game, %State{board: initial_board()})
  end

  @impl true
  def play(
        Domain.take(position: Domain.d2(col: col, row: row)),
        Domain.game(),
        %State{board: board}
      )
      when not is_nil(elem(board, row * 3 + col)) do
    {:error, :position_already_taken}
  end

  @impl true
  def play(
        Domain.take(player_number: player_number) = action,
        Domain.game(players: players) = game,
        %State{last_player_number: last_player_number} = state
      ) do
    cond do
      next_player_number(last_player_number, players) === player_number ->
        play_and_get_state(action, game, state)

      true ->
        {:error, :wrong_turn}
    end
  end

  @impl true
  def play(_, _, _) do
    {:error, :invalid_action}
  end

  @impl true
  def possible_actions(Domain.game(state: :draw), _state) do
    {:ok, []}
  end

  @impl true
  def possible_actions(Domain.game(state: :win), _state) do
    {:ok, []}
  end

  @impl true
  def possible_actions(
        Domain.game(players: [Domain.player(number: first_player_number) | _]),
        nil
      ) do
    board = initial_board()

    {
      :ok,
      Range.new(0, tuple_size(board) - 1)
      |> Enum.reduce([], fn i, acc ->
        value = elem(board, i)

        cond do
          is_nil(value) ->
            [
              Domain.take(
                player_number: first_player_number,
                position: Domain.d2(col: rem(i, 3), row: div(i, 3))
              )
              | acc
            ]

          true ->
            acc
        end
      end)
    }
  end

  @impl true
  def possible_actions(Domain.game(players: players), %State{
        board: board,
        last_player_number: last_player_number
      }) do
    player_number = next_player_number(last_player_number, players)

    {
      :ok,
      Range.new(0, tuple_size(board) - 1)
      |> Enum.reduce([], fn i, acc ->
        value = elem(board, i)

        cond do
          is_nil(value) ->
            [
              Domain.take(
                player_number: player_number,
                position: Domain.d2(col: rem(i, 3), row: div(i, 3))
              )
              | acc
            ]

          true ->
            acc
        end
      end)
    }
  end

  defp update_board(board, Domain.d2(col: col, row: row), player_number)
       when is_tuple(board) and is_player_number(player_number) do
    put_elem(board, row * 3 + col, player_number)
  end

  defp initial_board() do
    {nil, nil, nil, nil, nil, nil, nil, nil, nil}
  end

  defp next_player_number(last_player_number, players)
       when is_player_number(last_player_number) and is_list(players) do
    next_player_number(last_player_number, players, nil)
  end

  defp next_player_number(
         last_player_number,
         [Domain.player(number: first_player_number) | _],
         nil
       )
       when is_integer(last_player_number) and last_player_number < first_player_number do
    first_player_number
  end

  defp next_player_number(
         last_player_number,
         [Domain.player(number: first_player_number) | other_players],
         nil
       )
       when is_integer(last_player_number) do
    next_player_number(last_player_number, other_players, first_player_number)
  end

  defp next_player_number(
         last_player_number,
         [Domain.player(number: player_number) | _],
         first_player_number
       )
       when is_integer(last_player_number) and is_integer(first_player_number) and
              last_player_number < player_number do
    player_number
  end

  defp next_player_number(
         last_player_number,
         [Domain.player(number: player_number) | _],
         first_player_number
       )
       when is_integer(last_player_number) and is_integer(first_player_number) and
              last_player_number === player_number do
    first_player_number
  end

  defp play_and_get_state(
         Domain.take(
           player_number: player_number,
           position: position
         ) = action,
         Domain.game(),
         %State{board: board} = state
       ) do
    new_board = update_board(board, position, player_number)

    new_state = %State{
      state
      | board: new_board,
        last_player_number: player_number,
        last_position: position
    }

    cond do
      win?(player_number, position, new_board) ->
        {:ok, action, new_state, {:win, [player_number]}}

      0..8 |> Enum.all?(fn i -> not is_nil(elem(new_board, i)) end) ->
        {:ok, action, new_state, :draw}

      true ->
        {:ok, action, new_state, :playing}
    end
  end

  defp win?(player_number, Domain.d2() = position, board)
       when is_player_number(player_number) and is_tuple(board) do
    win_in_col?(player_number, position, board) or
      win_in_row?(player_number, position, board) or
      win_in_diagonal?(player_number, position, board)
  end

  defp win_in_col?(player_number, Domain.d2(col: action_col, row: action_row), board)
       when is_player_number(player_number) and is_tuple(board) do
    0..2
    |> Enum.all?(fn col ->
      col === action_col or elem(board, action_row * 3 + col) === player_number
    end)
  end

  defp win_in_row?(player_number, Domain.d2(col: action_col, row: action_row), board)
       when is_player_number(player_number) and is_tuple(board) do
    0..2
    |> Enum.all?(fn row ->
      row === action_row or elem(board, row * 3 + action_col) === player_number
    end)
  end

  defp win_in_diagonal?(player_number, Domain.d2(col: action_col, row: action_row), board)
       when is_player_number(player_number) and is_tuple(board) do
    0..2
    |> Enum.all?(fn i ->
      (i === action_col and i === action_row) or elem(board, i * 3 + i) === player_number
    end) or
      0..2
      |> Enum.all?(fn i ->
        (i === action_col and 2 - i === action_row) or
          elem(board, (2 - i) * 3 + i) === player_number
      end)
  end
end
