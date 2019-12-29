defmodule Boardr.Gaming.GameServerTest do
  use Boardr.DataCase

  alias Boardr.Gaming.GameServer
  alias Boardr.Mocks.Rules, as: Mock

  import Hammox

  setup :mock_rules_factory!

  setup do
    game = Fixtures.game()
    1..2 |> Enum.map(fn n -> Fixtures.player(game: game, number: n) end)

    %{
      game: game,
      server: start_supervised!({GameServer, game.id})
    }
  end

  test "receive an empty board from the game server when the rules produce no data", %{server: server} do
    expect(Mock, :board, fn _, _ -> {:ok, []} end)
    assert GenServer.call(server, :board) == {:ok, []}
  end

  test "receive no possible actions from the game server when the rules produce none", %{server: server} do
    expect(Mock, :possible_actions, fn _, _ -> {:ok, []} end)
    assert {:ok, actions} = GenServer.call(server, :possible_actions)
    assert length(actions) == 0
  end
end
