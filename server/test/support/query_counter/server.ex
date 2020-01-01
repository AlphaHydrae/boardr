defmodule QueryCounter.Server do
  use GenServer

  def start_link(_options \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def count_query(pid, query) when is_pid(pid) and is_binary(query) do
    GenServer.call(__MODULE__, {:count_query, pid, query})
  end

  def counted_queries(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:counted_queries, pid})
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(
        {:count_query, pid, query},
        _from,
        state
      )
      when is_pid(pid) and is_binary(query) do
    query_type =
      cond do
        String.match?(query, ~r/^BEGIN/i) -> :begin
        String.match?(query, ~r/^COMMIT/i) -> :commit
        String.match?(query, ~r/^DELETE/i) -> :delete
        String.match?(query, ~r/^INSERT/i) -> :insert
        String.match?(query, ~r/^ROLLBACK/i) -> :rollback
        String.match?(query, ~r/^SELECT/i) -> :select
        String.match?(query, ~r/^UPDATE/i) -> :update
        true -> :other
      end

    current_counts = Map.get(state, pid, %{})

    {
      :reply,
      :ok,
      Map.put(
        state,
        pid,
        Map.update(current_counts, query_type, 1, fn n -> n + 1 end)
      )
    }
  end

  @impl true
  def handle_call(
        {:counted_queries, pid},
        _from,
        state
      )
      when is_pid(pid) do
    {
      :reply,
      Map.get(state, pid),
      state
    }
  end
end
