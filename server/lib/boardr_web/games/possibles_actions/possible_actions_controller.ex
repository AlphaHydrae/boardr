defmodule BoardrWeb.Games.PossibleActionsController do
  use BoardrWeb, :controller

  alias Boardr.{Action,Game,GameInformation}
  alias Boardr.Rules.TicTacToe, as: Rules

  plug Authenticate, [:'api:games:show:possible-actions:index'] when action in [:index]

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    game = Repo.get!(Game, game_id)
    |> Repo.preload([actions: {from(a in Action, order_by: a.performed_at), [:player]}, players: []])

    game_info = GameInformation.for_game game
    possible_actions = Rules.possible_actions game_info

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game_id: game_id, possible_actions: possible_actions})
  end
end
