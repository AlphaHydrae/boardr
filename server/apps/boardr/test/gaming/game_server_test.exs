defmodule Boardr.Gaming.GameServerTest do
  use Boardr.DataCase

  alias Boardr.Game
  alias Boardr.Gaming.GameServer
  alias Boardr.Mocks.Rules, as: Mock

  import Hammox

  setup :mock_rules_factory!

  setup do
    game = Fixtures.game(state: "playing")
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

  test "receive no possible actions from the game server when the rules produce none", %{game: %Game{id: game_id}, server: server} do
    expect(Mock, :possible_actions, fn _, _, _ -> {:ok, []} end)
    assert {:ok, {possible_actions, %Game{id: ^game_id}}} = GenServer.call(server, {:possible_actions, %{}})
    assert length(possible_actions) == 0
  end
end
