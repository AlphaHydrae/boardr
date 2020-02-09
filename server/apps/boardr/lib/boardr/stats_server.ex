# TODO: use telemetry somehow
defmodule Boardr.StatsServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stats() do
    GenServer.call(__MODULE__, :stats)
  end

  # Server (callbacks)

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, compute_stats(), state}
  end

  defp compute_stats() do
    %{
      game_servers: count_local_game_servers(),
      swarm_processes: length(Swarm.registered())
    }
  end

  defp count_local_game_servers() do
    Swarm.registered() |> Enum.map(fn {_, pid} -> pid end) |> Enum.filter(fn pid ->
      try do
        Process.alive?(pid)
      rescue
        _ -> false
      end
    end) |> length()
  end
end
