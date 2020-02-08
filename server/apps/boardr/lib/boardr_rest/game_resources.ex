defmodule BoardrRest.GameResources do
  use BoardrRest

  alias Boardr.{Data, Game, Player}

  @behaviour BoardrRest.Resources

  @impl true
  def handle_operation(operation(type: :create, data: http_request(body: body, query_string: query_string)) = op) do
    with {:ok, {:user, user_id, _}} <- authorize(op, :user, :"api:games:create"),
         {:ok, game_properties} <- parse_json_object(body) do
      insert_game_and_player(user_id, game_properties, query_string)
    end
  end

  @impl true
  def handle_operation(
        operation(type: :retrieve, data: http_request(query_string: query_string))
      ) do
    with {:ok, filters} <- decode_game_filters(query_string) do
      list_games(filters)
    end
  end

  defp insert_game_and_player(user_id, game_properties, query_string)
       when is_binary(user_id) and is_map(game_properties) do
    game =
      %Game{creator_id: user_id, rules: "tic-tac-toe", settings: %{}}
      |> Game.changeset(game_properties)

    result =
      Multi.new()
      |> Multi.insert(:game, game, returning: [:id, :state])
      |> Multi.run(:player, fn repo, %{game: inserted_game} ->
        %Player{game_id: inserted_game.id, number: 1, user_id: user_id}
        |> repo.insert(returning: [:id])
      end)
      |> Repo.transaction()

    with {:ok, %{game: %Game{} = game, player: %Player{} = player}} <- result do
      {
        :ok,
        %Game{game | players: [player]},
        (query_string || "") |> URI.decode_query() |> Map.get("embed", []) |> Data.to_list() |> Enum.uniq()
      }
    end
  end

  def list_games(filters) when is_map(filters) do
    query = from(g in Game, select: g, group_by: g.id, order_by: [desc: g.created_at])

    query =
      if state = Map.get(filters, "state") do
        from(q in query, where: q.state in ^state)
      else
        query
      end

    query =
      if player_urls = Map.get(filters, "player") do
        # FIXME: improve URL parsing
        player_ids =
          Data.to_list(player_urls)
          |> Enum.map(fn url -> url |> String.split("/") |> List.last() end)
          |> Enum.map(fn id -> if Data.uuid?(id), do: id, else: false end)

        if Enum.all?(player_ids, & &1) do
          from(q in query, join: p in assoc(q, :players), where: p.id in ^player_ids)
        else
          false
        end
      else
        query
      end

    if query do
      games =
        query
        |> Repo.all()
        |> Repo.preload(:winners)

      embed = filters |> Map.get("embed", []) |> Data.to_list() |> Enum.uniq()

      games = if "boardr:players" in embed do
        games
        |> Repo.preload(players: from(p in Player, order_by: p.number))
      else
        games
      end

      {
        :ok,
        games,
        embed
      }
    else
      {:ok, [], []}
    end
  end

  defp decode_game_filters(nil), do: %{}

  defp decode_game_filters(query_string) when is_binary(query_string) do
    {
      :ok,
      URI.query_decoder(query_string)
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.update(acc, key, [value], fn previous_values -> previous_values ++ [value] end)
      end)
    }
  end
end
