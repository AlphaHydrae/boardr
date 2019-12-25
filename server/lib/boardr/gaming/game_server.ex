defmodule Boardr.Gaming.GameServer do
  use GenServer

  alias Boardr.{Action, Game, GameInformation, Player, Repo}
  alias Boardr.Auth.Identity
  alias Boardr.Rules.TicTacToe, as: Rules
  alias Ecto.{Changeset, Multi}
  import Ecto.Query, only: [from: 2]

  def start_link(game_id) when is_binary(game_id) do
    GenServer.start_link(__MODULE__, game_id)
  end

  def play(game_id, identity_id, action_properties)
      when is_binary(game_id) and is_binary(identity_id) and is_map(action_properties) do
    call_swarm(game_id, {:play, game_id, identity_id, action_properties})
  end

  # Server (callbacks)

  @impl true
  def init(game_id) when is_binary(game_id) do
    game =
      Repo.get!(Game, game_id)
      |> Repo.preload(
        actions: {from(a in Action, order_by: a.performed_at), [:player]},
        players: []
      )

    {:ok, GameInformation.for_game(game)}
  end

  @impl true
  def handle_call(
        {:play, game_id, identity_id, action_properties},
        _from,
        %GameInformation{} = game_info
      )
      when is_binary(game_id) and is_binary(identity_id) and is_map(action_properties) do
    with {:ok, new_game_info} <- handle_play(game_id, identity_id, action_properties) do
      {:reply, {:ok, new_game_info.last_action}, new_game_info}
    else
      error -> {:reply, error, game_info}
    end
  end

  # Gaming (functions)

  defp handle_play(game_id, identity_id, action_properties)
       when is_binary(game_id) and is_binary(identity_id) and is_map(action_properties) do
    identity = Repo.get!(Identity, identity_id)

    game =
      Repo.get!(Game, game_id)
      |> Repo.preload(
        actions: {from(a in Action, order_by: a.performed_at), [:player]},
        players: []
      )
      |> Repo.preload(:winners)

    # TODO: take player from game.players to avoid extra query
    player =
      Repo.one!(
        from(p in Player, where: p.game_id == ^game_id and p.user_id == ^identity.user_id)
      )

    game_information = GameInformation.for_game(game)
    possible_actions = Rules.possible_actions(game_information)

    {:ok, action, game_state, winners} =
      Rules.play(
        %GameInformation{game_information | possible_actions: possible_actions},
        player,
        action_properties
      )

    {:ok, result} = persist_action(%Action{action | game_id: game.id}, game, game_state, winners)
    {:ok, %GameInformation{game_information | last_action: result.action}}
  end

  defp persist_action(%Action{} = action, %Game{} = game, :draw, []) do
    Multi.new()
    |> Multi.insert(:action, action, returning: [:id])
    |> Multi.run(:game, fn repo, _ ->
      Game.changeset(game, %{state: "draw"})
      |> repo.update
    end)
    |> Repo.transaction()
  end

  defp persist_action(%Action{} = action, %Game{} = game, :playing, []) do
    Multi.new()
    |> Multi.insert(:action, action, returning: [:id])
    |> Multi.run(:game, fn repo, _ ->
      Game.changeset(game, %{state: "playing"})
      |> repo.update
    end)
    |> Repo.transaction()
  end

  defp persist_action(%Action{} = action, %Game{} = game, :win, [%Player{} | _] = winners) do
    Multi.new()
    |> Multi.insert(:action, action, returning: [:id])
    |> Multi.run(:game, fn repo, _ ->
      Game.changeset(game, %{state: "win"})
      |> Changeset.put_assoc(:winners, winners)
      |> repo.update
    end)
    |> Repo.transaction()
  end

  defp call_swarm(game_id, request) when is_binary(game_id) do
    {:ok, pid} =
      Swarm.whereis_or_register_name("game:#{game_id}", DynamicSupervisor, :start_child, [
        Boardr.DynamicSupervisor,
        {__MODULE__, game_id}
      ])

    GenServer.call(pid, request)
  end
end
