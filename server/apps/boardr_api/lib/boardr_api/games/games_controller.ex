defmodule BoardrApi.GamesController do
  use BoardrApi, :controller

  alias Boardr.{Data, Game, Player}
  alias BoardrRest.GameResources

  def create(%Conn{} = conn, _params) do
    with {:ok, %Game{} = game, embed} <- rest(conn, GameResources, :create) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{embed: embed, game: game})
    end
  end

  def index(%Conn{} = conn, params) when is_map(params) do
    with {:ok, games, embed} <- rest(conn, GameResources, :retrieve) do
      conn
      |> put_resp_content_type("application/hal+json")
      |> render(%{embed: embed, games: games})
    end
  end

  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    game =
      Repo.get!(Game, id)
      |> Repo.preload(:winners)

    embed = conn.query_string |> URI.decode_query() |> Map.get("embed", []) |> Data.to_list() |> Enum.uniq

    game = if "boardr:players" in embed do
      game |> Repo.preload(players: from(p in Player, order_by: p.number))
    else
      game
    end

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      embed: embed,
      game: game
    })
  end
end
