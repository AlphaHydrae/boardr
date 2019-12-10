defmodule BoardrWeb.Games.PossibleActionsController do
  use BoardrWeb, :controller

  alias Boardr.{Board,Game,GameInformation}
  alias Boardr.Rules.TicTacToe, as: Rules

  plug Authenticate, [:'api:games:show:possible-actions:index'] when action in [:index]

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    game = Repo.get!(Game, game_id)
    |> Repo.preload([actions: [:player], players: []])

    possible_actions = Rules.possible_actions %GameInformation{
      board: Board.board(game),
      last_action: List.last(Enum.sort(
        game.actions,
        fn a1, a2 ->
          DateTime.diff(a1.performed_at, a2.performed_at, :nanosecond)
        end
      )),
      players: game.players,
      settings: game.data
    }

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game_id: game_id, possible_actions: possible_actions})
  end
end
