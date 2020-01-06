defmodule Boardr.Rules.TicTacToeTest do
  use ExUnit.Case, async: true

  alias Boardr.Rules.Domain
  alias Boardr.Rules.TicTacToe

  import Domain

  require Domain

  @all_board_positions 0..2
                       |> Enum.flat_map(fn col -> 0..2 |> Enum.map(fn row -> {col, row} end) end)

  setup do
    %{
      game: Domain.game(players: 1..2 |> Enum.map(&Domain.player(number: &1)))
    }
  end

  test "the board is empty in a fresh game", %{game: game} do
    assert TicTacToe.board(game, nil) == {:ok, []}
  end

  test "all positions are indicated as takable by the first player in a fresh game",
       %{game: game} do
    assert {:ok, actions} = TicTacToe.possible_actions(%{}, game, nil)
    assert length(actions) == 9

    first_player_number = game |> Domain.game(:players) |> List.first() |> Domain.player(:number)

    for {col, row} <- @all_board_positions do
      assert Domain.take(
               player_number: first_player_number,
               position: Domain.d2(col: col, row: row)
             ) in actions
    end
  end

  for {col, row} <- @all_board_positions do
    @col col
    @row row

    test "the first player can take position #{col},#{row} in a fresh game", %{
      game: game
    } do
      assert {:ok, action, _new_state, :playing} = take(1, @col, @row, game)
    end

    test "the second player cannot play first by taking position #{col},#{row}", %{game: game} do
      assert {:error, :wrong_turn} = take(2, @col, @row, game)
    end

    test "the second player cannot take position #{col},#{row} if it was already taken by the first player",
         %{game: game} do
      assert {:ok, _action, state, :playing} = take(1, @col, @row, game)
      assert {:error, :position_already_taken} = take(2, @col, @row, game, state)
    end
  end

  test "the first player wins after completing the first row", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 0, 1, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 0, game, state)
    assert {:ok, _action, state, :playing} = take(2, 1, 1, game, state)
    assert {:ok, _action, _state, {:win, [1]}} = take(1, 2, 0, game, state)
  end

  test "the first player wins after completing the first column", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 1, 0, game, state)
    assert {:ok, _action, state, :playing} = take(1, 0, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 1, 1, game, state)
    assert {:ok, _action, _state, {:win, [1]}} = take(1, 0, 2, game, state)
  end

  test "the first player wins after completing the top-left to bottom-right diagonal", %{
    game: game
  } do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 1, 0, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 2, 0, game, state)
    assert {:ok, _action, _state, {:win, [1]}} = take(1, 2, 2, game, state)
  end

  test "the first player wins after completing the bottom-left to top-right diagonal", %{
    game: game
  } do
    assert {:ok, _action, state, :playing} = take(1, 0, 2, game)
    assert {:ok, _action, state, :playing} = take(2, 0, 0, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 0, 1, game, state)
    assert {:ok, _action, _state, {:win, [1]}} = take(1, 2, 0, game, state)
  end

  test "the game ends in a draw if no player wins", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 0, 1, game, state)
    assert {:ok, _action, state, :playing} = take(1, 0, 2, game, state)
    assert {:ok, _action, state, :playing} = take(2, 1, 1, game, state)
    assert {:ok, _action, state, :playing} = take(1, 2, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 2, 2, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 2, game, state)
    assert {:ok, _action, state, :playing} = take(2, 1, 0, game, state)
    assert {:ok, _action, _state, :draw} = take(1, 2, 0, game, state)
  end

  test "the first player cannot play twice in a row", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:error, :wrong_turn} = take(1, 0, 1, game, state)
  end

  @tag :slow
  test "all possible games should end in a win or a draw", %{game: game} do
    take_recursively(@all_board_positions, game)
  end

  defp take(player_number, col, row, Domain.game() = game, state \\ nil)
       when is_player_number(player_number) and
              is_position_coordinate(col) and is_position_coordinate(row) do
    TicTacToe.play(
      Domain.take(
        player_number: player_number,
        position: Domain.d2(col: col, row: row)
      ),
      game,
      state
    )
  end

  defp take_recursively(positions, Domain.game() = game, state \\ nil) when is_list(positions) do
    number_of_positions = length(positions)

    # Play each position.
    for i <- Range.new(0, number_of_positions - 1) do
      {{col, row}, remaining_positions} = List.pop_at(positions, i)
      player_number = 2 - rem(number_of_positions, 2)
      assert {:ok, _action, new_state, result} = take(player_number, col, row, game, state)

      # Check the result...
      case result do
        # If the game is still ongoing, check that there is at least 1 remaining
        # position on the board, then recursively play all remaining positions.
        :playing ->
          assert length(remaining_positions) >= 1
          take_recursively(remaining_positions, game, new_state)

        # In case of a win, check that the last player to play has won, and that
        # there are no more than 4 positions not taken on the board (it takes at
        # least 3 moves by the first player and 2 by the second player to win).
        {:win, player_numbers} ->
          assert player_numbers == [player_number]
          assert length(remaining_positions) <= 4

        # In case of a draw, check that all board positions were taken.
        :draw ->
          assert length(remaining_positions) === 0
      end
    end
  end
end
