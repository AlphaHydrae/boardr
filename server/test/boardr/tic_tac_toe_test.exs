defmodule Boardr.Rules.TicTacToeTest do
  use ExUnit.Case, async: true

  alias Boardr.Rules
  alias Boardr.Rules.TicTacToe

  require Boardr.Rules

  test "create an empty board" do
    assert TicTacToe.board(Rules.game(players: [], settings: %{}), nil) == {:ok, []}
  end
end
