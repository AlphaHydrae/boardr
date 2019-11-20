defmodule BoardrWeb.ApiView do
  use BoardrWeb, :view

  def render("index.json", _) do
    %{
      _links: %{
        'boardr:games' => Routes.games_url(BoardrWeb.Endpoint, :index),
        curies: [
          %{
            name: "boardr",
            href: "#{Routes.api_url(BoardrWeb.Endpoint, :index)}/{rel}",
            templated: true
          }
        ],
        self: Routes.api_url(BoardrWeb.Endpoint, :index)
      },
      version: Boardr.MixProject.project[:version]
    }
  end
end
