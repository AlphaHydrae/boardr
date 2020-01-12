defmodule Boardr.Telemetry do
  require Logger

  def handle_event(
        [:boardr, :repo, :query],
        %{total_time: total_time} = measurements,
        %{query: query},
        _config
      ) do
    total_time_ms = System.convert_time_unit(total_time, :native, :millisecond)
    if total_time_ms > slow_query_time() do
      Logger.warn(
        "Slow database query took #{total_time_ms}ms\nMeasurements: #{
          inspect(measurements)
        }\nQuery: #{query}"
      )
    end
  end

  defp slow_query_time() do
    :boardr
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:slow_query_time)
  end
end
