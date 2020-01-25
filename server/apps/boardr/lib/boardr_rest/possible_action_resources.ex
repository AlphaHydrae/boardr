defmodule BoardrRest.PossibleActionResources do
  use BoardrRest

  alias Boardr.Data
  alias Boardr.Game
  alias Boardr.Gaming.GameServer

  @behaviour BoardrRest.Resources

  @impl true
  def handle_operation(
        operation(
          type: :retrieve,
          id: game_id,
          data: http_request(query_string: query_string)
        )
      )
      when is_binary(game_id) do
    with {:ok, {filters, embed}} <- decode_action_filters(query_string) do
      determine_possible_actions(game_id, filters, embed)
    end
  end

  defp determine_possible_actions(game_id, filters, embed)
       when is_binary(game_id) and is_map(filters) and is_list(embed) do
    with {:ok, {possible_actions, %Game{} = game}} <-
           GameServer.possible_actions(game_id, filters) do
      {
        :ok,
        {
          possible_actions,
          game,
          embed
        }
      }
    end
  end

  defp decode_action_filters(nil), do: %{}

  defp decode_action_filters(query_string) when is_binary(query_string) do
    query = URI.decode_query(query_string)
    filters = %{}

    player_ids =
      query
      |> Map.get("player")
      |> Data.to_list()
      |> Enum.map(fn url -> url |> String.split("/") |> List.last() end)
      |> Enum.map(fn id ->
        if Data.uuid?(id), do: id, else: "00000000-0000-0000-0000-000000000000"
      end)

    filters =
      if length(player_ids) >= 1, do: Map.put(filters, :player_ids, player_ids), else: filters

    {
      :ok,
      {
        filters,
        query["embed"] |> Data.to_list() |> Enum.uniq()
      }
    }
  end
end
