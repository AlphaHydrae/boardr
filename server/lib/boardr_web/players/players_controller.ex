defmodule BoardrWeb.PlayersController do
  use BoardrWeb, :controller

  alias Boardr.Auth.Identity
  alias Boardr.Player

  plug Authenticate, [:'api:players:create'] when action in [:create]
  plug Authenticate, [:'api:players:show'] when action in [:show]

  def create(%Conn{assigns: %{auth: %{"sub" => identity_id}}} = conn, %{"game_id" => game_id}) do
    identity = Repo.get! Identity, identity_id
    with {:ok, player} <- join_game(game_id, identity.user_id) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_players_url(Endpoint, :show, player.game_id, player.id))
      |> render(%{player: player})
    end
  end

  def show(%Conn{} = conn, %{"game_id" => game_id, "id" => id}) do
    player = Repo.get! Player, id

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{player: player})
  end

  defp join_game(game_id, user_id) when is_binary(game_id) and is_binary(user_id) do
    %Player{game_id: game_id, number: 0, user_id: user_id}
    |> Repo.insert()
  end
end
