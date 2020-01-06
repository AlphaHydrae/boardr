defmodule BoardrApi.Games.PlayersController do
  use BoardrApi, :controller

  alias Boardr.{Game,Player}
  alias Boardr.Gaming.LobbyServer

  plug Authenticate, [:'api:players:create'] when action in [:create]
  plug Authenticate, [:'api:players:show'] when action in [:show]

  def create(%Conn{assigns: %{auth: %{"sub" => user_id}}} = conn, %{"game_id" => game_id}) do
    game_state = Repo.one!(from(g in Game, select: g.state, where: g.id == ^game_id))
    with {:ok, %Player{} = player} <- join_game(game_id, game_state, user_id) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_players_url(Endpoint, :show, player.game_id, player.id))
      |> render(%{player: player})
    end
  end

  def show(%Conn{} = conn, %{"game_id" => game_id, "id" => id}) do
    player = Repo.one! from p in Player, where: p.game_id == ^game_id and p.id == ^id

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{player: player})
  end

  defp join_game(game_id, "waiting_for_players", user_id) when is_binary(game_id) and is_binary(user_id) do
    LobbyServer.join(game_id, user_id)
  end

  defp join_game(game_id, game_state, user_id) when is_binary(game_id) and is_binary(game_state) and is_binary(user_id) do
    {:error, :game_already_started}
  end
end
