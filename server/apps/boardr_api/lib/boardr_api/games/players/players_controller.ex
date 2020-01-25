defmodule BoardrApi.Games.PlayersController do
  use BoardrApi, :controller

  alias Boardr.Player
  alias BoardrRest.PlayerResources

  def create(%Conn{} = conn, %{"game_id" => game_id}) do
    with {:ok, %Player{} = player} <- rest(conn, PlayerResources, :create, %{game_id: game_id}) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header(
        "location",
        Routes.games_players_url(Endpoint, :show, player.game_id, player.id)
      )
      |> render(%{player: player})
    end
  end

  def show(%Conn{} = conn, %{"game_id" => game_id, "id" => id}) do
    player = Repo.one!(from(p in Player, where: p.game_id == ^game_id and p.id == ^id))

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{player: player})
  end
end
