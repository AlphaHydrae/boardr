defmodule Boardr.StatsServer do
  use GenServer

  @stats_refresh_interval 2_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stats() do
    case :ets.lookup(:stats, :cache) do
      [cache: cache] -> cache
      _ -> GenServer.call(__MODULE__, :stats)
    end
  end

  # Server (callbacks)

  @impl true
  def init(_) do
    {:ok, nil, {:continue, :init}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_continue(:init, nil) do
    :ets.new(:stats, [:named_table, :protected, :set])
    {:noreply, compute_stats()}
  end

  @impl true
  def handle_info(:refresh, _) do
    {:noreply, compute_stats()}
  end

  defp compute_stats() do

    stats = %{
      game_servers: length(Swarm.members(:game_servers)),
      swarm_processes: length(Swarm.registered())
    }

    :ets.insert(:stats, {:cache, stats})
    Process.send_after(self(), :refresh, @stats_refresh_interval)

    stats
  end
end
