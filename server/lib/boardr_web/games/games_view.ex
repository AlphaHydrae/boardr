defmodule BoardrWeb.GamesView do
  use BoardrWeb, :view

  def render("index.json", %{games: games}) do
    %{
      _links: %{
        curies: [
          %{
            name: "boardr",
            href: "#{Routes.api_url(BoardrWeb.Endpoint, :index)}/rels/{rel}",
            templated: true
          }
        ],
        self: Routes.games_url(BoardrWeb.Endpoint, :index)
      },
      _embedded: %{
        'boardr:games': games
      }
    }
  end
end
