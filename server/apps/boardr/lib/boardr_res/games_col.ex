defmodule BoardrRes.GamesCollection do
  use BoardrRes

  alias Boardr.{Game, Player}

  @behaviour BoardrRes.Collection

  @impl true
  def create(representation, options() = opts) when is_map(representation) do
    representation
    |> to_context(opts)
    |> authorize(:'api:games:create')
    >>> insert_game_and_player()
  end

  @impl true
  def retrieve(options() = opts) do
    context(options: opts) |> list_games()
  end

  defp insert_game_and_player(context(assigns: %{claims: %{"sub" => user_id}}, representation: rep)) when is_map(rep) do
    game = %Game{creator_id: user_id, rules: "tic-tac-toe", settings: %{}}
    |> Game.changeset(rep)

    result = Multi.new()
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

  def list_games(context(options: options(filters: filters))) when is_map(filters) do
    query = from g in Game, select: g, group_by: g.id, order_by: [desc: g.created_at]

    query = if state = Map.get(filters, :state) do
      from q in query, where: q.state == ^state
    else
      query
    end

    query = if player_ids = Map.get(filters, :player_ids) do
      from q in query, join: p in assoc(q, :players), where: p.id in ^player_ids
    else
      query
    end

    {
      :ok,
      query
      |> Repo.all()
      |> Repo.preload(:winners)
    }
  end
end
