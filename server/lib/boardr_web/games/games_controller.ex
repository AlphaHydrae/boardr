defmodule BoardrWeb.GamesController do
  use BoardrWeb, :controller
  alias Boardr.{Repo, Game}

  def index(conn, _) do
    games = Repo.all(Game)
    render(conn, %{games: games})
  end
end
