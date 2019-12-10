defmodule BoardrWeb.ActionsController do
  use BoardrWeb, :controller

  alias Boardr.Auth.Identity
  alias Boardr.{Action,Board,Game,GameInformation,Player}
  alias Boardr.Rules.TicTacToe, as: Rules

  plug Authenticate, [:'api:games:update:actions:create'] when action in [:create]
  plug Authenticate, [:'api:games:show:actions:index'] when action in [:index]
  plug Authenticate, [:'api:games:show:actions:show'] when action in [:show]

  def create(%Conn{assigns: %{auth: %{"sub" => identity_id}}} = conn, %{"game_id" => game_id} = action_properties) do
    with {:ok, action} <- play(game_id, identity_id, action_properties) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_actions_url(Endpoint, :show, action.game_id, action.id))
      |> render(%{action: action})
    end
  end

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    actions = Repo.all from(a in Action, order_by: [desc: a.performed_at], where: a.game_id == ^game_id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{actions: actions, game_id: game_id})
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    action = Repo.one! from(a in Action, where: a.game_id == ^game_id and a.id == ^id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{action: action})
  end

  defp play(game_id, identity_id, action_properties) when is_binary(game_id) and is_binary(identity_id) and is_map(action_properties) do
    identity = Repo.get! Identity, identity_id

    game = Repo.get!(Game, game_id)
    |> Repo.preload([actions: [:player], players: []])

    last_action = List.last game.actions

    # TODO: take player from game.players to avoid extra query
    player = Repo.one! from(p in Player, where: p.game_id == ^game_id and p.user_id == ^identity.user_id)

    game_information = %GameInformation{
      board: Board.board(game),
      data: %{},
      last_action: last_action,
      players: game.players,
      settings: game.data
    }

    possible_actions = Rules.possible_actions game_information

    {:ok, action} = Rules.play %GameInformation{game_information | possible_actions: possible_actions}, player, action_properties

    %Action{action | game_id: game_id}
    |> Repo.insert(returning: [:id])
  end
end
