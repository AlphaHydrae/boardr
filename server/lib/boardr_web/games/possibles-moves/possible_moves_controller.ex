defmodule BoardrWeb.Games.PossibleMovesController do
  use BoardrWeb, :controller

  alias Boardr.{Board,Game,GameInformation}
  alias Boardr.Rules.TicTacToe, as: Rules

  plug Authenticate, [:'api:games:show:possible-moves:index'] when action in [:index]

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    game = Repo.get!(Game, game_id)
    |> Repo.preload([moves: [:player], players: []])

    possible_moves = Rules.possible_moves %GameInformation{board: Board.board(game), players: game.players, settings: game.data}

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game_id: game_id, possible_moves: possible_moves})
  end
end
