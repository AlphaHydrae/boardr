defmodule BoardrApi.Games.ActionsController do
  use BoardrApi, :controller

  alias Boardr.{Action, Player, Repo}
  alias Boardr.Gaming.GameServer

  plug(Authenticate, [:"api:games:update:actions:create"] when action in [:create])

  def create(
        %Conn{assigns: %{auth: %{"sub" => user_id}}} = conn,
        %{"game_id" => game_id} = action_properties
      ) do
    {player_id, game_state} =
      Repo.one!(
        from(p in Player,
          join: g in assoc(p, :game),
          select: {p.id, g.state},
          where: p.game_id == ^game_id and p.user_id == ^user_id
        )
      )

    with {:ok, action} <-
           play(game_id, game_state, player_id, Map.delete(action_properties, "game_id")) do
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

  defp play(game_id, "waiting_for_players", player_id, action_properties)
       when is_binary(game_id) and is_binary(player_id) and is_map(action_properties) do
    {:error, {:game_error, :game_not_started}}
  end

  defp play(game_id, "playing", player_id, action_properties)
       when is_binary(game_id) and is_binary(player_id) and is_map(action_properties) do
    GameServer.play(game_id, player_id, Map.delete(action_properties, "game_id"))
  end

  defp play(game_id, game_state, player_id, action_properties)
       when is_binary(game_id) and is_binary(game_state) and is_binary(player_id) and
              is_map(action_properties) do
    {:error, {:game_error, :game_finished}}
  end
end
