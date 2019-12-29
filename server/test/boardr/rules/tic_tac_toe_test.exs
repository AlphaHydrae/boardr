defmodule Boardr.Rules.TicTacToeTest do
  use ExUnit.Case, async: true

  alias Boardr.Rules.Domain
  alias Boardr.Rules.TicTacToe

  require Boardr.Rules.Domain

  @all_board_positions 0..2
                       |> Enum.flat_map(fn col -> 0..2 |> Enum.map(fn row -> {col, row} end) end)

  setup do
    players = [Domain.player(number: 1), Domain.player(number: 2)]
    game = Domain.game(players: players)

    %{game: game}
  end

  test "the board is empty in a fresh game", %{game: game} do
    assert TicTacToe.board(game, nil) == {:ok, []}
  end

  test "all positions are indicated as takable by the first player in a fresh game",
       %{game: game} do
    assert {:ok, actions} = TicTacToe.possible_actions(game, nil)
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
      first_player_number =
        game |> Domain.game(:players) |> List.first() |> Domain.player(:number)

      assert {:ok, action, _new_state, :playing} =
               TicTacToe.play(
                 Domain.take(
                   player_number: first_player_number,
                   position: Domain.d2(col: @col, row: @row)
                 ),
                 game,
                 nil
               )
    end

    test "the second player cannot play first by taking position #{col},#{row}", %{game: game} do
      assert {:error, :wrong_turn} = take(2, @col, @row, game)
    end

    test "the second player cannot take position #{col},#{row} if it was already taken by the first player", %{game: game} do
      assert {:ok, _action, state, :playing} = take(1, @col, @row, game)
      assert {:error, :position_already_taken} = take(2, @col, @row, game, state)
    end
  end

  test "the first player wins after completing the first row", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 0, 1, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 0, game, state)
    assert {:ok, _action, state, :playing} = take(2, 1, 1, game, state)
    assert {:ok, _action, state, {:win, [1]}} = take(1, 2, 0, game, state)
  end

  test "the first player wins after completing the first column", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 1, 0, game, state)
    assert {:ok, _action, state, :playing} = take(1, 0, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 1, 1, game, state)
    assert {:ok, _action, state, {:win, [1]}} = take(1, 0, 2, game, state)
  end

  test "the first player wins after completing the top-left to bottom-right diagonal", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 0, game)
    assert {:ok, _action, state, :playing} = take(2, 1, 0, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 2, 0, game, state)
    assert {:ok, _action, state, {:win, [1]}} = take(1, 2, 2, game, state)
  end

  test "the first player wins after completing the bottom-left to top-right diagonal", %{game: game} do
    assert {:ok, _action, state, :playing} = take(1, 0, 2, game)
    assert {:ok, _action, state, :playing} = take(2, 0, 0, game, state)
    assert {:ok, _action, state, :playing} = take(1, 1, 1, game, state)
    assert {:ok, _action, state, :playing} = take(2, 0, 1, game, state)
    assert {:ok, _action, state, {:win, [1]}} = take(1, 2, 0, game, state)
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

  defp take(player_number, col, row, Domain.game() = game, state \\ nil)
       when is_integer(player_number) and is_integer(col) and is_integer(row) do
    TicTacToe.play(
      Domain.take(player_number: player_number, position: Domain.d2(col: col, row: row)),
      game,
      state
    )
  end
end
