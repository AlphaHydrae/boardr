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

    filters = if player_urls = query["player"] do
      # FIXME: improve URL parsing
      player_ids =
        Data.to_list(player_urls)
        |> Enum.map(fn url -> url |> String.split("/") |> List.last() end)
        |> Enum.map(fn id -> if Data.uuid?(id), do: id, else: false end)

      if Enum.all?(player_ids, &(&1)) do
        Map.put(filters, :player_ids, player_ids)
      else
        false
      end
    else
      filters
    end

    game = Repo.get!(Game, game_id)
    embed = Data.to_list(query["embed"])

    cond do
      filters && game.state == "playing" ->
        with {:ok, possible_actions} <-
               GameServer.possible_actions(game.id, Map.delete(filters, :game_id)) do
          {:ok, {possible_actions, game, embed}}
        end

      true ->
        {:ok, {[], game, embed}}
    end
  end
end
