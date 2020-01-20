defmodule BoardrRest.PossibleActionsService do
  use BoardrRest

  alias Boardr.Data
  alias Boardr.Game
  alias Boardr.Gaming.GameServer

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :retrieve) = op) do
    op |> determine_possible_actions()
  end

  defp determine_possible_actions(operation(id: game_id, query: query_string))
       when is_binary(game_id) do
    query = URI.decode_query(query_string)
    filters = %{}

    player_ids = query
    |> Map.get("player")
    |> Data.to_list()
    |> Enum.map(fn url -> url |> String.split("/") |> List.last() end)
    |> Enum.map(fn id -> if Data.uuid?(id), do: id, else: "00000000-0000-0000-0000-000000000000" end)

    filters = if length(player_ids) >= 1, do: Map.put(filters, :player_ids, player_ids), else: filters

    with {:ok, {possible_actions, %Game{} = game}} <-
            GameServer.possible_actions(game_id, filters) do
      {
        :ok,
        {
          possible_actions,
          game,
          query["embed"] |> Data.to_list() |> Enum.uniq()
        }
      }
    end
  end
end
