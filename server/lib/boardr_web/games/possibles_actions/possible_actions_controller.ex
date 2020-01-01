defmodule BoardrWeb.Games.PossibleActionsController do
  use BoardrWeb, :controller

  alias Boardr.{Game, Repo}
  alias Boardr.Gaming.GameServer

  def index(%Conn{} = conn, %{"game_id" => game_id}) do

    game = Repo.get!(Game, game_id)
    |> Repo.preload([:players])

    {:ok, possible_actions} = if game.state == "waiting_for_players" and length(game.players) < 2 do
      {:ok, []}
    else
      GameServer.possible_actions(game.id)
    end

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      game: game,
      possible_actions: possible_actions
    })
  end
end
