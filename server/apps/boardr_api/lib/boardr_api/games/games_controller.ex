defmodule BoardrApi.GamesController do
  use BoardrApi, :controller

  alias Boardr.Game
  alias BoardrRest.GamesService

  require BoardrRes

  def create(%Conn{} = conn, _params) do
    with {:ok, %Game{} = game} <- distribute_to_service(conn, GamesService, :create) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{game: game})
    end
  end

  def index(%Conn{} = conn, params) when is_map(params) do
    with {:ok, games} <- distribute_to_service(conn, GamesService, :retrieve) do
      conn
      |> put_resp_content_type("application/hal+json")
      |> render(%{games: games})
    end
  end

  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    game =
      Repo.get!(Game, id)
      |> Repo.preload([:winners])

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game: game})
  end
end
