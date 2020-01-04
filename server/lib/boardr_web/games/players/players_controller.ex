defmodule BoardrWeb.Games.PlayersController do
  use BoardrWeb, :controller

  alias Boardr.{Game,Player}

  plug Authenticate, [:'api:players:create'] when action in [:create]
  plug Authenticate, [:'api:players:show'] when action in [:show]

  def create(%Conn{assigns: %{auth: %{"sub" => user_id}}} = conn, %{"game_id" => game_id}) do
    with {:ok, %{player: player}} <- join_game(game_id, user_id) do
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

  defp join_game(game_id, user_id) when is_binary(game_id) and is_binary(user_id) do
    player_numbers = Repo.all(from p in Player, order_by: p.number, select: p.number, where: p.game_id == ^game_id)
    next_available_player_number = Enum.reduce_while player_numbers, 1, fn n, acc -> if n > acc, do: {:halt, acc}, else: {:cont, acc + 1} end

    player = Player.changeset(%Player{game_id: game_id, user_id: user_id}, %{number: next_available_player_number})

    result = Multi.new()
    |> Multi.insert(:player, player, returning: [:id])
    |> Multi.run(:game, fn repo, %{player: inserted_player} ->
      if inserted_player.number == 2 do
        Game.changeset(%Game{id: game_id}, %{state: "playing"})
        |> repo.update()
      else
        {:ok, nil}
      end
    end)
    |> Repo.transaction()

    case result do
      {:ok, data} -> {:ok, data}
      {:error, :player, error, _} -> {:error, error}
    end
  end
end
