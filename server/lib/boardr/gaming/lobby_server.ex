defmodule Boardr.Gaming.LobbyServer do
  use GenServer

  alias Boardr.{Game, Player, Repo}
  alias Ecto.{Multi}

  import Ecto.Query, only: [from: 2]

  require Boardr.Rules.Domain
  require Logger
  require Record

  Record.defrecordp(:state_record, :lobby_server_state, [:game])

  @default_timeout 5_000

  def start_link(game_id) when is_binary(game_id) do
    GenServer.start_link(__MODULE__, game_id)
  end

  def join(game_id, user_id) do
    call_swarm(game_id, {:join, user_id})
  end

  # Server (callbacks)

  @impl true
  def init(game_id) when is_binary(game_id) do
    {:ok, nil, {:continue, {:init, game_id}}}
  end

  @impl true
  def handle_call(
    {:join, user_id},
    _from,
    state_record(game: %Game{id: game_id, players: players, state: "waiting_for_players"} = game) = state
  ) when is_binary(user_id) do

    player_numbers = Enum.map(players, &(&1.number))
    next_available_player_number = Enum.reduce_while player_numbers, 1, fn n, acc -> if n > acc, do: {:halt, acc}, else: {:cont, acc + 1} end

    player = Player.changeset(%Player{game_id: game_id, user_id: user_id}, %{number: next_available_player_number})

    {:ok, %{game: updated_game, player: created_player}} = Multi.new()
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

    {
      :reply,
      {:ok, created_player},
      state_record(state, game: %Game{updated_game | players: players ++ [player]}),
      @default_timeout
    }
  end

  @impl true
  def handle_call(
    {:join, user_id},
    _from,
    state_record() = state
  ) when is_binary(user_id) do
    {:reply, {:error, :game_already_started}, state, @default_timeout}
  end

  @impl true
  def handle_continue({:init, game_id}, _state) when is_binary(game_id) do
    Logger.debug("Initializing lobby server for game #{game_id}")

    game = Repo.one!(from(g in Game, left_join: p in assoc(g, :players), preload: [players: p], where: g.id == ^game_id))

    Logger.info("Initialized lobby server for game #{game_id} with #{length(game.players)} players")

    {:noreply, state_record(game: game), @default_timeout}
  end

  @impl true
  def handle_info(:timeout, state_record(game: %Game{id: game_id}) = state) do
    Logger.info("Shutting down inactive lobby server for game #{game_id}")
    {:stop, {:shutdown, :timeout}, state}
  end

  # Gaming (functions)

  defp call_swarm(game_id, request) when is_binary(game_id) do
    {:ok, pid} =
      Swarm.whereis_or_register_name("lobby:#{game_id}", DynamicSupervisor, :start_child, [
        Boardr.DynamicSupervisor,
        Supervisor.child_spec({__MODULE__, game_id}, restart: :transient)
      ])

    GenServer.call(pid, request)
  end
end
