defmodule BoardrApi.ApiRootView do
  use BoardrApi, :view

  def render("index.json", _assigns) do
    api_document(%{
      version: List.to_string(Application.spec(:boardr, :vsn))
    })
    |> put_boardr_link(:game, Routes.games_url(Endpoint, :show, "") <> "{id}", :templated)
    |> put_boardr_link(:games, Routes.games_url(Endpoint, :index))
    |> put_boardr_link(:identities, Routes.identities_url(Endpoint, :index))
    |> put_boardr_link(:identity, Routes.identities_url(Endpoint, :show, "") <> "{id}", :templated)
    |> put_boardr_link(:'local-auth', Routes.auth_url(Endpoint, :local))
    # TODO: implement users index
    |> put_boardr_link(:users, Routes.users_url(Endpoint, :create))
    |> put_link(:self, Routes.api_root_url(Endpoint, :index))
  end
end
