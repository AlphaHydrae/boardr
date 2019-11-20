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
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{game: game})
    end
  end

  def index(conn, _) do
    games = Repo.all(from g in Game, order_by: [desc: g.created_at])
    render(conn, %{games: games})
  end

  def show(conn, %{"id" => id}) do
    game = Repo.get!(Game, id)
    render(conn, %{game: game})
  end
end
