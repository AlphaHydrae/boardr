defmodule BoardrApi.Games.BoardView do
  use BoardrApi, :view

  alias Boardr.Board

  def render("show.json", %{board: %Board{data: data, dimensions: dimensions, game_id: game_id}}) do
    %{
      data: data,
      dimensions: dimensions
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game_id) }
    })
    |> put_hal_self_link(:games_board_url, [:show, game_id])
  end
end
