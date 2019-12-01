defmodule BoardrWeb.MovesController do
  use BoardrWeb, :controller
  alias Boardr.{Repo, Move}

  def create(conn, params) do
    with {:ok, move} <-
           Move.changeset(%Move{}, params)
           |> Repo.insert(returning: [:id]) do
      conn
      |> put_status(201)
      |> put_resp_header("location", Routes.moves_url(Endpoint, :show, move.id))
      |> render(%{move: move})
    end
  end

  def index(conn, _) do
    moves = Repo.all(from(m in Move, order_by: [desc: m.created_at]))
    render(conn, %{moves: moves})
  end

  def show(conn, %{"id" => id}) do
    move = Repo.get!(Move, id)
    render(conn, %{move: move})
  end
end
