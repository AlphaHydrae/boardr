defmodule BoardrRest.GamesService do
  use BoardrRest

  alias Boardr.{Data, Game, Player}

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op |> authorize(:"api:games:create") >>>
      parse_json_object_entity() >>>
      insert_game_and_player()
  end

  @impl true
  def handle_operation(operation(type: :retrieve) = op) do
    op |> list_games()
  end

  defp insert_game_and_player(
         operation(options: %{authorization_claims: %{"sub" => user_id}, parsed_entity: entity})
       )
       when is_map(entity) do
    game =
      %Game{creator_id: user_id, rules: "tic-tac-toe", settings: %{}}
      |> Game.changeset(entity)

    result =
      Multi.new()
      |> Multi.insert(:game, game, returning: [:id])
      |> Multi.run(:player, fn repo, %{game: inserted_game} ->
        %Player{game_id: inserted_game.id, number: 1, user_id: user_id}
        |> repo.insert(returning: [:id])
      end)
      |> Repo.transaction()

    with {:ok, %{game: %Game{} = game, player: %Player{} = player}} <- result do
      {:ok, %Game{game | players: [player]}}
    end
  end

  def list_games(operation(query: query_string)) when is_binary(query_string) do
    filters = URI.decode_query(query_string)

    query = from(g in Game, select: g, group_by: g.id, order_by: [desc: g.created_at])

    query =
      if state = Map.get(filters, "state") do
        from(q in query, where: q.state == ^state)
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

        if Enum.all?(player_ids, &(&1)) do
          from(q in query, join: p in assoc(q, :players), where: p.id in ^player_ids)
        else
          false
        end
      else
        query
      end

    if query do
      {
        :ok,
        query
        |> Repo.all()
        |> Repo.preload(:winners)
      }
    else
      {:ok, []}
    end
  end
end
