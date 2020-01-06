defmodule Boardr.Telemetry do
  require Logger

  def handle_event(
        [:boardr, :repo, :query],
        %{total_time: total_time} = measurements,
        %{query: query},
        _config
      ) do
    if total_time > 100_000_000 do
      Logger.warn(
        "Slow database query took #{System.convert_time_unit(total_time, :native, :millisecond)}ms\nMeasurements: #{
          inspect(measurements)
        }\nQuery: #{query}"
      )
    end
  end
end
