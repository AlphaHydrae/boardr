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
end
