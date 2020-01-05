defmodule BoardrWeb.ApiRootView do
  use BoardrWeb, :view
  use Memoize

  def render("index.json", _assigns) do
    api_root()
  end

  defmemop api_root() do
    api_document(%{
      version: List.to_string(Application.spec(:boardr, :vsn))
    })
    |> put_boardr_link(:games, Routes.games_url(BoardrWeb.Endpoint, :index))
    |> put_boardr_link(:identities, Routes.identities_url(BoardrWeb.Endpoint, :index))
    # TODO: implement users index
    |> put_boardr_link(:users, Routes.users_url(BoardrWeb.Endpoint, :create))
    |> put_link(:self, Routes.api_root_url(BoardrWeb.Endpoint, :index))
  end
end
