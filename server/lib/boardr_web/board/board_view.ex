defmodule BoardrWeb.BoardView do
  use BoardrWeb, :view

  alias Boardr.Board

  def render("show.json", %{board: %Board{data: data, game: game}}) do
    %{
      data: data
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game.id) }
    })
    |> put_hal_self_link(:games_board_url, [:show, game.id])
  end
end
