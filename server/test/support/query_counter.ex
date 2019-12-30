defmodule BoardrWeb.QueryCounter do
  def count_queries(%{test: test} = context) when is_atom(test) do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    :ok =
      :telemetry.attach(
        test,
        [:boardr, :repo, :query],
        &__MODULE__.handle_event/4,
        %{agent: agent}
      )

    ExUnit.Callbacks.on_exit(fn -> :ok = :telemetry.detach(test) end)
    Map.put(context, :query_counter, agent)
  end

  def counted_queries(agent) when is_pid(agent) do
    Agent.get(agent, fn state -> state end)
  end

  def counted_queries(%{query_counter: agent}) when is_pid(agent) do
    Agent.get(agent, fn state -> state end)
  end

  def handle_event([:boardr, :repo, :query], _measurements, metadata, %{
        agent: agent
      }) do
    query = String.trim(metadata.query)

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

    :ok = Agent.update(agent, fn state -> Map.update(state, query_type, 1, fn n -> n + 1 end) end)
  end
end