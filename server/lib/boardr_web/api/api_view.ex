defmodule BoardrWeb.ApiView do
  use BoardrWeb, :view

  def render("index.json", _) do
    %{
      version: Boardr.MixProject.project[:version]
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:api_url, [:index])
    |> put_hal_links(%{
      'boardr:games' => Routes.games_url(BoardrWeb.Endpoint, :index)
    })
  end
end
