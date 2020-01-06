defmodule BoardrApi.Games.ActionsController do
  use BoardrApi, :controller

  alias Boardr.{Action,Player,Repo}
  alias Boardr.Gaming.GameServer

  plug Authenticate, [:'api:games:update:actions:create'] when action in [:create]
  plug Authenticate, [:'api:games:show:actions:index'] when action in [:index]
  plug Authenticate, [:'api:games:show:actions:show'] when action in [:show]

  def create(%Conn{assigns: %{auth: %{"sub" => user_id}}} = conn, %{"game_id" => game_id} = action_properties) do
    player_id = Repo.one!(from(p in Player, select: p.id, where: p.game_id == ^game_id and p.user_id == ^user_id))
    with {:ok, action} <- GameServer.play(game_id, player_id, Map.delete(action_properties, "game_id")) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_actions_url(Endpoint, :show, action.game_id, action.id))
      |> render(%{action: action})
    end
  end

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    actions = Repo.all from(a in Action, order_by: [desc: a.performed_at], where: a.game_id == ^game_id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{actions: actions, game_id: game_id})
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    action = Repo.one! from(a in Action, where: a.game_id == ^game_id and a.id == ^id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{action: action})
  end
end
