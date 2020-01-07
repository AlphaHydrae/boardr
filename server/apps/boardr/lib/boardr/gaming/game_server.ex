defmodule Boardr.Gaming.GameServer do
  use GenServer

  alias Boardr.{Action, Game, Player, Repo}
  alias Boardr.Gaming.GameServer.State
  alias Boardr.Rules.Domain
  alias Ecto.{Changeset, Multi}

  import Ecto.Query, only: [from: 2]

  require Boardr.Rules.Domain
  require Logger

  @default_timeout 5_000

  def start_link(game_id) when is_binary(game_id) do
    GenServer.start_link(__MODULE__, game_id)
  end

  def board(game_id) when is_binary(game_id) do
    call_swarm(game_id, :board)
  end

  def play(game_id, player_id, action_properties)
      when is_binary(game_id) and is_binary(player_id) and is_map(action_properties) do
    call_swarm(game_id, {:play, player_id, action_properties})
  end

  def possible_actions(game_id, filters \\ %{}) do
    call_swarm(game_id, {:possible_actions, filters})
  end

  # Server (callbacks)

  @impl true
  def init(game_id) when is_binary(game_id) do
    {:ok, nil, {:continue, {:init, game_id}}}
  end

  @impl true
  def handle_call(
    :board,
    _from,
    %State{rules_game: rules_game, rules_state: rules_state} = state
  ) do
    {
      :reply,
      get_rules!(rules_game).board(rules_game, rules_state),
      state,
      @default_timeout
    }
  end

  @impl true
  def handle_call(
        {:play, player_id, action_properties},
        _from,
        %State{game: game, rules_game: rules_game, rules_state: rules_state} = state
      )
      when is_binary(player_id) and is_map(action_properties) do
    # TODO: check player not nil
    player = game.players |> Enum.find(fn player -> player.id === player_id end)

    with {:ok, action, new_rules_state, game_result} <-
           get_rules!(rules_game).play(
             Domain.take(
               player_number: player.number,
               position: Domain.position_from_list(action_properties["position"])
             ),
             rules_game,
             rules_state
           ),
         {:ok, %{action: persisted_action, game: persisted_game}} <- persist_action(action, player, game, game_result) do
      {
        :reply,
        {:ok, persisted_action},
        %State{state | game: persisted_game, rules_state: new_rules_state},
        @default_timeout
      }
    else
      error ->
        {:reply, error, state, @default_timeout}
    end
  end

  @impl true
  def handle_call(
    {:possible_actions, filters},
    _from,
    %State{game: game, rules_game: Domain.game(players: rules_players) = rules_game, rules_state: rules_state} = state
  ) when is_map(filters) do

    rules_filters = %{}

    rules_filters = if player_ids = Map.get(filters, :player_ids) do
      player_numbers = game.players |> Enum.filter(fn player -> player.id in player_ids end) |> Enum.map(&(&1.number))
      Map.put(rules_filters, :players, rules_players |> Enum.filter(fn player -> Domain.player(player, :number) in player_numbers end))
    else
      rules_filters
    end

    {
      :reply,
      get_rules!(rules_game).possible_actions(rules_filters, rules_game, rules_state),
      state,
      @default_timeout
    }
  end

  @impl true
  def handle_continue({:init, game_id}, _state) when is_binary(game_id) do
    Logger.debug("Initializing game server for game #{game_id}")

    players_query = from(p in Player, order_by: p.number)

    game =
      Repo.get!(Game, game_id)
      |> Repo.preload(
        players: players_query,
        winners: []
      )

    rules_players =
      game.players
      |> Enum.map(fn %Player{number: player_number} -> Domain.player(number: player_number) end)

    rules_game = Domain.game(players: rules_players, rules: game.rules, settings: game.settings, state: String.to_atom(game.state))

    {:ok, {rules_state, number_of_actions}} =
      Repo.transaction(fn ->
        from(a in Action,
          join: p in assoc(a, :player),
          order_by: a.performed_at,
          select: {a, p},
          where: a.game_id == ^game_id
        )
        |> Repo.stream(max_rows: 100)
        |> Enum.reduce({nil, 0}, fn {action, player}, {current_rules_state, n} ->
          result =
            get_rules!(rules_game).play(
              Domain.take(
                player_number: player.number,
                position: Domain.position_from_list(action.position)
              ),
              rules_game,
              current_rules_state
            )

          case result do
            {:ok, _, new_state, _} -> {new_state, n + 1}
          end
        end)
      end)

    Logger.info("Initialized game server for game #{game_id} with #{number_of_actions} actions")

    {:noreply, %State{game: game, rules_game: rules_game, rules_state: rules_state}, @default_timeout}
  end

  @impl true
  def handle_info(:timeout, %State{game: %Game{id: game_id}} = state) do
    Logger.info("Shutting down inactive game server for game #{game_id}")
    {:stop, {:shutdown, :timeout}, state}
  end

  # Gaming (functions)

  defp persist_action(
         Domain.take() = action,
         %Player{id: player_id},
         %Game{id: game_id} = game,
         game_result
       ) do
    Multi.new()
    |> Multi.insert(:action, action_record_to_struct(action, game_id, player_id), returning: [:id])
    |> Multi.run(:game, fn repo, %{action: persisted_action} ->
      game_result_changeset(game, persisted_action, game_result)
      |> repo.update(force: true)
    end)
    |> Repo.transaction()
  end

  defp game_result_changeset(%Game{} = game, %Action{performed_at: action_performed_at}, :playing) do
    Game.changeset(game, %{state: "playing", updated_at: action_performed_at})
  end

  defp game_result_changeset(%Game{} = game, %Action{performed_at: action_performed_at}, :draw) do
    Game.changeset(game, %{state: "draw", updated_at: action_performed_at})
  end

  defp game_result_changeset(%Game{players: players} = game, %Action{performed_at: action_performed_at}, {:win, winners}) when is_list(winners) do
    Game.changeset(game, %{state: "win", updated_at: action_performed_at})
    |> Changeset.put_assoc(:winners, winners |> Enum.map(fn player_number -> players |> Enum.find(fn player -> player.number === player_number end) end))
  end

  defp action_record_to_struct(Domain.take(position: position), game_id, player_id)
       when is_binary(game_id) and is_binary(player_id) do
    %Action{
      game_id: game_id,
      player_id: player_id,
      position: Domain.position_to_list(position),
      type: "take"
    }
  end

  defp call_swarm(game_id, request) when is_binary(game_id) do
    {:ok, pid} =
      Swarm.whereis_or_register_name(
        "game:#{game_id}",
        DynamicSupervisor,
        :start_child,
        [
          Boardr.DynamicSupervisor,
          Supervisor.child_spec({__MODULE__, game_id}, restart: :transient)
        ],
        10_000
      )

    # FIXME: restart server if shutting down due to timeout
    GenServer.call(pid, request)
  end

  defp get_rules!(Domain.game(rules: rules_name)) do
    get_rules!(rules_name)
  end

  defp get_rules!(rules_name) when is_binary(rules_name) do
    factory = :boardr
    |> Application.fetch_env!(Boardr)
    |> Keyword.fetch!(:rules_factory)

    factory.get_rules(rules_name)
  end
end