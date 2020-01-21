defmodule BoardrRest.GamesService do
  use BoardrRest

  alias Boardr.{Data, Game, Player}
  # alias BoardrRest.PlayersService

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op |> authorize(:"api:games:create") >>>
      insert_game_and_player() >>>
      to_json_value(%{})
      # TODO: auto-embed boardr:player
  end

  @impl true
  def handle_operation(operation(type: :retrieve) = op) do
    op |> list_games()
  end

  def to_json_value(%Game{} = game, %{embed: embed}) when is_list(embed) do
    api_hal_document(%{
      createdAt: game.created_at,
      rules: game.rules,
      settings: game.settings,
      state: game.state,
      title: game.title,
      updatedAt: game.updated_at
    })
    |> Data.drop_nil()
    # |> put_hal_links(%{
    #   'boardr:actions': %{ href: Routes.games_actions_url(Endpoint, :index, game.id) },
    #   'boardr:board': %{ href: Routes.games_board_url(Endpoint, :show, game.id) },
    #   'boardr:creator': %{ href: Routes.users_url(Endpoint, :show, game.creator_id) },
    #   'boardr:players': %{ href: Routes.games_players_url(Endpoint, :create, game.id) },
    #   'boardr:possible-actions': %{ href: Routes.games_possible_actions_url(Endpoint, :index, game.id) },
    #   collection: %{ href: Routes.games_url(Endpoint, :index) }
    # })
    # |> put_hal_self_link(:games_url, [:show, game.id])
    # |> put_embedded(
    #   :'boardr:winners',
    #   Enum.map(game.players, fn p -> PlayersService.to_json_value(p, %{}) end)
    # )
    # |> put_embedded(
    #   :'boardr:player',
    #   PlayersService.to_json_value(List.first(game.players), %{})
    # )
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
