defmodule BoardrApi.Games.BoardController do
  use BoardrApi, :controller

  alias Boardr.Board
  alias Boardr.Gaming.GameServer

  def show(%Conn{} = conn, %{"game_id" => game_id}) when is_binary(game_id) do

    {:ok, board_data} = GameServer.board(game_id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      board: %Board{data: board_data, dimensions: [3, 3], game_id: game_id}
    })
  end
end
