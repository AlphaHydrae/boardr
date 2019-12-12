defmodule BoardrWeb.GamesController do
  use BoardrWeb, :controller

  alias Boardr.Auth.Identity
  alias Boardr.Game

  plug Authenticate, [:'api:games:create'] when action in [:create]

  def create(
    %Conn{assigns: %{auth: %{"sub" => identity_id}}} = conn,
    game_properties
  ) when is_map(game_properties) and is_binary(identity_id) do
    identity = Repo.get! Identity, identity_id
    with {:ok, game} <- create_game(game_properties, identity.user_id) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{game: game})
    end
  end

  def index(%Conn{} = conn, _) do
    games = Repo.all(from(g in Game, order_by: [desc: g.created_at]))

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{games: games})
  end

  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    game = Repo.get!(Game, id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game: game})
  end

  defp create_game(game_properties, user_id) when is_binary(user_id) do
    %Game{creator_id: user_id, settings: %{}}
    |> Game.changeset(game_properties)
    |> Repo.insert(returning: [:id])
  end
end
