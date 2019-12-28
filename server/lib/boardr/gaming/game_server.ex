defmodule Boardr.Gaming.GameServer do
  use GenServer

  alias Boardr.{Action, Game, Player, Position, Repo, Rules}
  alias Boardr.Gaming.GameServer.State
  alias Boardr.Rules.TicTacToe, as: CurrentRules
  alias Ecto.{Changeset, Multi}

  import Ecto.Query, only: [from: 2]

  require Boardr.Position
  require Boardr.Rules
  require Logger

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

  def possible_actions(game_id) do
    call_swarm(game_id, :possible_actions)
  end

  # Server (callbacks)

  @impl true
  def init(game_id) when is_binary(game_id) do
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
      |> Enum.map(fn %Player{number: player_number} -> Rules.player(number: player_number) end)

    rules_game = Rules.game(players: rules_players, settings: game.settings)

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
            CurrentRules.play(
              Rules.action(
                type: String.to_atom(action.type),
                player_number: player.number,
                position: Position.parse(action.position)
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

    {:ok, %State{game: game, rules_state: rules_state}}
  end

  @impl true
  def handle_call(
    :board,
    _from,
    %State{game: game, rules_state: rules_state} = state
  ) do

    # TODO: cache this
    rules_players =
      game.players
      |> Enum.map(fn %Player{number: player_number} -> Rules.player(number: player_number) end)

    rules_game = Rules.game(players: rules_players, settings: game.settings)

    {:reply, CurrentRules.board(rules_game, rules_state), state}
  end

  @impl true
  def handle_call(
        {:play, player_id, action_properties},
        _from,
        %State{game: game, rules_state: rules_state} = state
      )
      when is_binary(player_id) and is_map(action_properties) do
    # TODO: check player not nil
    player = game.players |> Enum.find(fn player -> player.id === player_id end)

    # TODO: cache this
    rules_players =
      game.players
      |> Enum.map(fn %Player{number: player_number} -> Rules.player(number: player_number) end)

    rules_game = Rules.game(players: rules_players, settings: game.settings)

    with {:ok, action, new_rules_state, game_result} <-
           CurrentRules.play(
             Rules.action(
               type: :take,
               player_number: player.number,
               position: Position.from_list(action_properties["position"])
             ),
             rules_game,
             rules_state
           ),
         {:ok, %{action: persisted_action, game: persisted_game}} <- persist_action(action, player, game, game_result) do
      {
        :reply,
        {:ok, persisted_action},
        %State{state | game: persisted_game, rules_state: new_rules_state}
      }
    else
      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(
    :possible_actions,
    _from,
    %State{game: game, rules_state: rules_state} = state
  ) do
    # TODO: cache this
    rules_players =
      game.players
      |> Enum.map(fn %Player{number: player_number} -> Rules.player(number: player_number) end)

    rules_game = Rules.game(players: rules_players, settings: game.settings)

    {:reply, CurrentRules.possible_actions(rules_game, rules_state), state}
  end

  # Gaming (functions)

  defp persist_action(
         Rules.action() = action,
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
    Game.changeset(game, %{updated_at: action_performed_at})
  end

  defp game_result_changeset(%Game{} = game, %Action{performed_at: action_performed_at}, :draw) do
    Game.changeset(game, %{state: "draw", updated_at: action_performed_at})
  end

  defp game_result_changeset(%Game{players: players} = game, %Action{performed_at: action_performed_at}, {:win, winners}) when is_list(winners) do
    Game.changeset(game, %{state: "win", updated_at: action_performed_at})
    |> Changeset.put_assoc(:winners, winners |> Enum.map(fn player_number -> players |> Enum.find(fn player -> player.number === player_number end) end))
  end

  defp action_record_to_struct(Rules.action(position: position, type: type), game_id, player_id)
       when is_binary(game_id) and is_binary(player_id) do
    %Action{
      game_id: game_id,
      player_id: player_id,
      position: Position.dump(position),
      type: Atom.to_string(type)
    }
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