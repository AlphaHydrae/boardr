defmodule BoardrApi.AuthController do
  use BoardrApi, :controller

  alias Boardr.Auth.{Token, User}

  plug Plug.Parsers, parsers: [:json], json_decoder: Jason

  def google(%Conn{} = conn, params) when is_map(params) do

    url = :uri_string.parse("https://oauth2.googleapis.com/tokeninfo")
    query_params = :uri_string.compose_query([{"id_token", params["tokenId"]}])
    url = :uri_string.recompose(Map.put(url, :query, query_params))

    {:ok, %HTTPoison.Response{body: json, status_code: 200}} = HTTPoison.get(url)
    {:ok, body} = Jason.decode(json)

    conn
    |> render(%{result: body})
  end

  # FIXME: require password
  def local(%Conn{} = conn, %{"email" => email}) do
    user = Repo.one!(from(u in User, join: i in assoc(u, :identities), where: i.email == ^email, group_by: u.id))
    with {:ok, token} <- Token.generate(user) do
      conn
      |> render(%{token: token})
    end
  end
end
