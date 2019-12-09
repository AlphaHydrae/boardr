defmodule BoardrWeb.MovesController do
  use BoardrWeb, :controller

  alias Boardr.Auth.Identity
  alias Boardr.{Board,Game,GameInformation,Move,Player}
  alias Boardr.Rules.TicTacToe, as: Rules

  plug Authenticate, [:'api:games:update:moves:create'] when action in [:create]
  plug Authenticate, [:'api:games:show:moves:index'] when action in [:index]
  plug Authenticate, [:'api:games:show:moves:show'] when action in [:show]

  def create(%Conn{assigns: %{auth: %{"sub" => identity_id}}} = conn, %{"game_id" => game_id} = move_properties) do
    with {:ok, move} <- play(game_id, identity_id, move_properties) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_moves_url(Endpoint, :show, move.game_id, move.id))
      |> render(%{move: move})
    end
  end

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    moves = Repo.all from(m in Move, order_by: [desc: m.played_at], where: m.game_id == ^game_id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game_id: game_id, moves: moves})
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    move = Repo.one! from(m in Move, where: m.game_id == ^game_id and m.id == ^id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{move: move})
  end

  defp play(game_id, identity_id, move_properties) when is_binary(game_id) and is_binary(identity_id) and is_map(move_properties) do
    identity = Repo.get! Identity, identity_id

    game = Repo.get!(Game, game_id)
    |> Repo.preload([moves: [:player], players: []])

    last_move = List.last game.moves

    # TODO: take player from game.players to avoid extra query
    player = Repo.one! from(p in Player, where: p.game_id == ^game_id and p.user_id == ^identity.user_id)

    game_information = %GameInformation{
      board: Board.board(game),
      data: %{},
      last_move: last_move,
      players: game.players,
      settings: game.data
    }

    possible_moves = Rules.possible_moves game_information

    {:ok, move} = Rules.play %GameInformation{game_information | possible_moves: possible_moves}, player, move_properties

    %Move{move | game_id: game_id}
    |> Repo.insert(returning: [:id])
  end
end
