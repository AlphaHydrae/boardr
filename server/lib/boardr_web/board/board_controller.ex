defmodule BoardrWeb.BoardController do
  use BoardrWeb, :controller

  alias Boardr.{Board,Game}

  plug Authenticate, [:'api:games:show:board:show'] when action in [:show]

  def show(%Conn{} = conn, %{"game_id" => game_id}) when is_binary(game_id) do
    game = Repo.get!(Game, game_id)
    |> Repo.preload([moves: [:player], players: []])

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      board: %Board{data: Board.board(game), game: game}
    })
  end
end
