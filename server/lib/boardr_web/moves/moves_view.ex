defmodule BoardrWeb.MovesView do
  use BoardrWeb, :view

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
    %{}
  end
end
