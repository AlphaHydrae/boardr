defmodule BoardrWeb.ApiView do
  use BoardrWeb, :view

  def render("index.json", _assigns) do
    api_document(%{
      version: List.to_string(Application.spec(:boardr, :vsn))
    })
    |> put_boardr_link(:games, Routes.games_url(BoardrWeb.Endpoint, :index))
    |> put_boardr_link(:identities, Routes.identities_url(BoardrWeb.Endpoint, :index))
    # TODO: implement users index
    |> put_boardr_link(:users, Routes.users_url(BoardrWeb.Endpoint, :create))
    |> put_link(:self, Routes.api_url(BoardrWeb.Endpoint, :index))
  end
end
