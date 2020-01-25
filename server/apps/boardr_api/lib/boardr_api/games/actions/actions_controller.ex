defmodule BoardrApi.Games.ActionsController do
  use BoardrApi, :controller

  alias Boardr.{Action, Repo}
  alias BoardrRest.ActionResources

  def create(%Conn{} = conn, %{"game_id" => game_id}) when is_binary(game_id) do
    with {:ok, %Action{} = action} <- rest(conn, ActionResources, :create, %{game_id: game_id}) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header(
        "location",
        Routes.games_actions_url(Endpoint, :show, action.game_id, action.id)
      )
      |> render(%{action: action})
    end
  end

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    actions =
      Repo.all(from(a in Action, order_by: [desc: a.performed_at], where: a.game_id == ^game_id))

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{actions: actions, game_id: game_id})
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    action = Repo.one!(from(a in Action, where: a.game_id == ^game_id and a.id == ^id))

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{action: action})
  end
end
