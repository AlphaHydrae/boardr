defmodule BoardrWeb.GamesController do
  use BoardrWeb, :controller
  alias Boardr.{Repo, Game}

  def create(conn, params) do
    with {:ok, game} <-
           %Game{data: %{}}
           |> Game.changeset(params)
           |> Repo.insert(returning: [:id]) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{game: game})
    end
  end

  def index(conn, _) do
    games = Repo.all(from(g in Game, order_by: [desc: g.created_at]))
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{games: games})
  end

  def show(conn, %{"id" => id}) do
    game = Repo.get!(Game, id)
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game: game})
  end
end
