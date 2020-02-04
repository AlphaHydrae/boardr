defmodule Boardr.Gaming.GameServer do
  use GenServer

  alias Boardr.{Action, Game, Player, Repo, Rules}
  alias Boardr.Rules.Domain
  alias Ecto.{Changeset, Multi}

  import Ecto.Query, only: [from: 2]

  require Boardr.Rules.Domain
  require Logger
  require Record

  @type game ::
          record(:state_record,
            game: Game.t() | nil,
            game_id: binary,
            rules: Rules.t(),
            rules_game: Domain.game() | nil,
            rules_state: map | nil
          )
  Record.defrecord(:state_record, __MODULE__,
    game: nil,
    game_id: nil,
    rules: nil,
    rules_game: nil,
    rules_state: nil
  )

  @default_timeout 60_000

  def start_link(game_id) when is_binary(game_id) do
    GenServer.start_link(__MODULE__, game_id)
  end

  def board(game_id) when is_binary(game_id) do
    call_swarm(game_id, :board)
  end

  def join(game_id, user_id) do
    call_swarm(game_id, {:join, user_id})
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
    Process.flag(:trap_exit, true)
    {:ok, state_record(game_id: game_id)}
  end

  @impl true
  def handle_call(args, from, state_record(game: nil) = state) do
    handle_call(args, from, load_state_from_database(state))
  end

  @impl true
  def handle_call(
        :board,
        _from,
        state_record(rules: rules, rules_game: rules_game, rules_state: rules_state) = state
      ) do
    reply(rules.board(rules_game, rules_state), state)
  end

  @impl true
  def handle_call(
        {:join, user_id},
        _from,
        state_record(
          game: %Game{id: game_id, players: players, state: "waiting_for_players"} = game,
          rules_game: Domain.game(players: domain_players) = rules_game
        ) = state
      )
      when is_binary(user_id) do
    player_numbers = Enum.map(players, & &1.number)

    next_available_player_number =
      Enum.reduce_while(player_numbers, 1, fn n, acc ->
        if n > acc, do: {:halt, acc}, else: {:cont, acc + 1}
      end)

    player =
      %Player{game_id: game_id, user_id: user_id}
      |> Player.changeset(%{number: next_available_player_number})

    {:ok, %{game: updated_game, player: created_player}} =
      Multi.new()
      |> Multi.insert(:player, player, returning: [:id])
      |> Multi.run(:game, fn repo, %{player: inserted_player} ->
        if inserted_player.number == 2 do
          %Game{id: game_id}
          |> Game.changeset(%{state: "playing"})
          |> repo.update()
        else
          {:ok, game}
        end
      end)
      |> Repo.transaction()

    new_players = players ++ [created_player]
    new_domain_players = domain_players ++ [Domain.player(number: created_player.number)]

    reply(
      created_player,
      state_record(
        state,
        game: %Game{game | players: new_players, state: updated_game.state},
        rules_game:
          Domain.game(rules_game, players: new_domain_players, state: updated_game.state)
      )
    )
  end

  @impl true
  def handle_call(
        {:join, user_id},
        _from,
        state_record() = state
      )
      when is_binary(user_id) do
    game_error_reply(:game_already_started, state)
  end

  @impl true
  def handle_call(
        {:play, user_id, action_properties},
        _from,
        state_record(game: %{state: "waiting_for_players"}) = state
      )
      when is_binary(user_id) and is_map(action_properties) do
    game_error_reply(:game_not_started, state)
  end

  @impl true
  def handle_call(
        {:play, user_id, action_properties},
        _from,
        state_record(
          game: %Game{state: "playing"} = game,
          rules: rules,
          rules_game: rules_game,
          rules_state: rules_state
        ) = state
      )
      when is_binary(user_id) and is_map(action_properties) do
    with {:ok, player} <- get_player(game, user_id),
         {:ok, action, new_rules_state, game_result} <-
           rules.play(
             Domain.take(
               player_number: player.number,
               position: Domain.position_from_list(action_properties["position"])
             ),
             rules_game,
             rules_state
           ),
         {:ok, %{action: persisted_action, game: persisted_game}} <-
           persist_action(action, player, game, game_result) do
      reply(
        persisted_action,
        state_record(state, game: persisted_game, rules_state: new_rules_state)
      )
    else
      {:error, error} ->
        case error do
          {:game_error, game_error} -> game_error_reply(game_error, state)
          other_error -> error_reply(other_error, state)
        end
    end
  end

  @impl true
  def handle_call(
        {:play, user_id, action_properties},
        _from,
        state_record() = state
      )
      when is_binary(user_id) and is_map(action_properties) do
    game_error_reply(:game_finished, state)
  end

  @impl true
  def handle_call(
        {:possible_actions, filters},
        _from,
        state_record(
          game: %Game{state: "playing"} = game,
          rules: rules,
          rules_game: rules_game,
          rules_state: rules_state
        ) = state
      )
      when is_map(filters) do
    rules_filters = %{}

    rules_filters =
      if player_ids = Map.get(filters, :player_ids) do
        Map.put(
          rules_filters,
          :players,
          game.players
          |> Enum.filter(fn player -> player.id in player_ids end)
          |> Enum.map(& &1.number)
        )
      else
        rules_filters
      end

    {:ok, possible_domain_actions} =
      rules.possible_actions(rules_filters, rules_game, rules_state)

    possible_actions =
      Enum.map(possible_domain_actions, fn a ->
        %Action{
          game_id: game.id,
          player_id:
            Enum.find(game.players, fn p -> p.number == Domain.take(a, :player_number) end).id,
          position: a |> Domain.take(:position) |> Domain.position_to_list(),
          type: "take"
        }
      end)

    reply({possible_actions, game}, state)
  end

  @impl true
  def handle_call({:possible_actions, filters}, _from, state_record(game: game) = state)
      when is_map(filters) do
    reply({[], game}, state)
  end

  @impl true
  def handle_call(
        {:swarm, :begin_handoff},
        _from,
        state_record(game_id: game_id) = state
      ) do
    Logger.debug("Swarm beginning handoff of game server for game #{game_id}")
    {:reply, :restart, state}
  end

  @impl true
  def handle_cast(
        {:swarm, :end_handoff, state_record() = handed_off_state},
        state_record(game: nil, game_id: game_id)
      ) do
    Logger.debug("Swarm ending handoff of game server for game #{game_id}")
    {:noreply, handed_off_state}
  end

  @impl true
  def handle_cast(
        {:swarm, :resolve_conflict, _delay},
        state_record() = state
      ) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:timeout, state_record(game_id: game_id) = state) do
    Logger.info("Shutting down inactive game server for game #{game_id}")
    {:stop, {:shutdown, :timeout}, state}
  end

  @impl true
  def handle_info(
        {:swarm, :die},
        state_record(game_id: game_id) = state
      ) do
    Logger.info("Swarm shutting down game server for game #{game_id}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Game server terminating due to #{inspect(reason)}")
    unless is_nil(state), do: Swarm.Tracker.handoff(__MODULE__, state)
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

  defp game_result_changeset(
         %Game{players: players} = game,
         %Action{performed_at: action_performed_at},
         {:win, winners}
       )
       when is_list(winners) do
    Game.changeset(game, %{state: "win", updated_at: action_performed_at})
    |> Changeset.put_assoc(
      :winners,
      winners
      |> Enum.map(fn player_number ->
        players |> Enum.find(fn player -> player.number === player_number end)
      end)
    )
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

  defp call_swarm(game_id, request, retry \\ 3, error_details \\ nil)

  defp call_swarm(game_id, _request, -1, error_details) when is_binary(game_id) do
    raise "Game server process not found: #{inspect(error_details)})}"
  end

  defp call_swarm(game_id, request, retry, _error_details)
       when is_binary(game_id) and is_integer(retry) and retry >= 0 do
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

    try do
      GenServer.call(pid, request, 10_000)
    catch
      :exit, {:noproc, details} ->
        Logger.warn(
          "Trying to start offline game server for game #{game_id} (retries left: #{retry - 1})"
        )

        Swarm.Tracker.untrack(pid)
        call_swarm(game_id, request, retry - 1, details)
    end
  end

  defp get_player(%Game{players: players}, user_id) do
    case Enum.find(players, fn p -> p.user_id == user_id end) do
      nil -> {:error, {:game_error, :user_not_in_game}}
      player -> {:ok, player}
    end
  end

  defp get_rules!(rules_name) when is_binary(rules_name) do
    factory =
      :boardr
      |> Application.fetch_env!(Boardr)
      |> Keyword.fetch!(:rules_factory)

    factory.get_rules(rules_name)
  end

  defp load_state_from_database(state_record(game_id: game_id) = state) do
    Logger.debug("Initializing game server for game #{game_id}")

    players_query = from(p in Player, order_by: p.number)

    game =
      Repo.get!(Game, game_id)
      |> Repo.preload(
        players: players_query,
        winners: []
      )

    rules = get_rules!(game.rules)

    rules_players =
      game.players
      |> Enum.map(fn %Player{number: player_number} -> Domain.player(number: player_number) end)

    rules_game =
      Domain.game(
        players: rules_players,
        rules: game.rules,
        settings: game.settings,
        state: :playing
      )

    {:ok, {rules_state, number_of_actions}} =
      Repo.transaction(fn ->
        from(a in Action,
          join: p in assoc(a, :player),
          order_by: a.performed_at,
          select: {a, p},
          where: a.game_id == ^game_id
        )
        # FIXME: why does Repo.stream make 3 queries?
        # |> Repo.stream(max_rows: 100)
        |> Repo.all()
        |> Enum.reduce({nil, 0}, fn {action, player}, {current_rules_state, n} ->
          result =
            rules.play(
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

    state_record(state, game: game, rules: rules, rules_game: rules_game, rules_state: rules_state)
  end

  def error_reply(err, state_record() = state) do
    {
      :reply,
      {:error, err},
      state,
      @default_timeout
    }
  end

  def game_error_reply(err, state_record() = state) do
    error_reply({:game_error, err}, state)
  end

  def reply({:ok, value}, state_record() = state) do
    reply(value, state)
  end

  def reply(value, state_record() = state) do
    {
      :reply,
      {:ok, value},
      state,
      @default_timeout
    }
  end
end
