defmodule QueryCounter do
  defmacro __using__(_opts) do
    quote do
      import Asserter.Assertions
    end
  end

  def start() do
    QueryCounter.Server.start_link()
  end

  def count_queries(test) when is_atom(test) do
    count_queries(%{test: test})
  end

  def count_queries(%{test: test}) when is_atom(test) do
    %Postgrex.Result{connection_id: connection_id} =
      Ecto.Adapters.SQL.query!(
        Boardr.Repo,
        "SELECT 1",
        []
      )

    :ok =
      :telemetry.attach(
        test,
        [:boardr, :repo, :query],
        &__MODULE__.handle_event/4,
        %{connection_id: connection_id, test_pid: self()}
      )

    ExUnit.Callbacks.on_exit(fn -> :ok = :telemetry.detach(test) end)
    :ok
  end

  def counted_queries() do
    QueryCounter.Server.counted_queries(self())
  end

  def handle_event([:boardr, :repo, :query], _measurements, metadata, %{
        connection_id: connection_id,
        test_pid: test_pid
      }) do
    if Map.has_key?(metadata, :result) do
      query = String.trim(metadata.query)

      case metadata.result do
        {:ok, %Postgrex.Result{connection_id: ^connection_id}} ->
          QueryCounter.Server.count_query(test_pid, query)

        _ ->
          :ok
      end
    end
  end
end
