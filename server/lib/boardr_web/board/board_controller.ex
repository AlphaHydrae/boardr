defmodule BoardrWeb.BoardController do
  use BoardrWeb, :controller

  alias Boardr.{Action,Board,Game,GameInformation}

  plug Authenticate, [:'api:games:show:board:show'] when action in [:show]

  def show(%Conn{} = conn, %{"game_id" => game_id}) when is_binary(game_id) do
    game = Repo.get!(Game, game_id)
    |> Repo.preload([actions: {from(a in Action, order_by: a.performed_at), [:player]}, players: []])

    game_info = GameInformation.for_game game

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      board: %Board{data: game_info.board, dimensions: [3, 3], game: game}
    })
  end
end
