defmodule BoardrApi.GamesController do
  use BoardrApi, :controller

  alias Boardr.{Game,Player}

  plug Authenticate, [:'api:games:create'] when action in [:create]

  def create(
    %Conn{assigns: %{auth: %{"sub" => user_id}}} = conn,
    game_properties
  ) when is_map(game_properties) and is_binary(user_id) do
    with {:ok, %{game: game, player: player}} <- create_game(game_properties, user_id) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{game: game, player: player})
    end
  end

  def index(%Conn{} = conn, _) do

    query = from g in Game, order_by: [desc: g.created_at]

    query = if state = conn.query_params["state"] do
      from q in query, where: q.state == ^state
    else
      query
    end

    games = query
    |> Repo.all()
    |> Repo.preload([:winners])

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{games: games})
  end

  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    game = Repo.get!(Game, id)
    |> Repo.preload([:winners])

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game: game})
  end

  defp create_game(game_properties, user_id) when is_binary(user_id) do
    game = Game.changeset(%Game{creator_id: user_id, rules: "tic-tac-toe", settings: %{}}, game_properties)

    Multi.new()
    |> Multi.insert(:game, game, returning: [:id])
    |> Multi.run(:player, fn repo, %{game: inserted_game} ->
        %Player{game_id: inserted_game.id, number: 1, user_id: user_id}
        |> repo.insert(returning: [:id])
    end)
    |> Repo.transaction()
  end
end
