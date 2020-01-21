defmodule BoardrApi.ApiRootController do
  use BoardrApi, :controller

  import BoardrRest.HalDocument, only: [put_link: 3]
  import BoardrApi.ViewHelpers, only: [api_document: 1, put_boardr_link: 3]

  def index(%Conn{} = conn, params) when is_map(params) do
    json(
      conn,
      api_document(%{
        version: List.to_string(Application.spec(:boardr, :vsn))
      })
      |> put_boardr_link(:games, Routes.games_url(Endpoint, :index))
      |> put_boardr_link(:identities, Routes.identities_url(Endpoint, :index))
      # TODO: implement users index
      |> put_boardr_link(:users, Routes.users_url(Endpoint, :create))
      |> put_link(:self, Routes.api_root_url(Endpoint, :index))
    )
  end
end
