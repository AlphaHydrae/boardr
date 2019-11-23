defmodule BoardrWeb.MovesView do
  use BoardrWeb, :view
  alias Boardr.{Move}

  def render("create.json", %{move: move}) do
    render_move move
  end

  def render("index.json", %{moves: moves}) do
    %{
      _embedded: %{
        'boardr:moves': render_many(moves, __MODULE__, "show.json", as: :move)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:moves_url, [:index])
  end

  def render("show.json", %{move: move}) do
    render_move move
  end

  defp render_move(%Move{} = move) do
    %{
      createdAt: move.created_at,
      data: move.data,
      id: move.id,
      updatedAt: move.updated_at
    }
    |> omit_nil()
    |> put_hal_curies_link()
    |> put_hal_links(%{
      collection: %{ href: Routes.moves_url(Endpoint, :index) },
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, move.game_id) }
    })
    |> put_hal_self_link(:moves_url, [:show, move.id])
  end
end
