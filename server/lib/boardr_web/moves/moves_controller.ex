defmodule BoardrWeb.MovesController do
  use BoardrWeb, :controller
  alias Boardr.{Repo, Game, Move}

  def index(conn, _) do
    render(conn, %{moves: []})
  end
end
