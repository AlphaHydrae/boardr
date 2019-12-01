defmodule BoardrWeb.AuthController do
  use BoardrWeb, :controller

  def google(conn, params) do

    url = :uri_string.parse("https://oauth2.googleapis.com/tokeninfo")
    query_params = :uri_string.compose_query([{"id_token", params["tokenId"]}])
    url = :uri_string.recompose(Map.put(url, :query, query_params))

    {:ok, %HTTPoison.Response{body: json, status_code: 200}} = HTTPoison.get(url)
    {:ok, body} = Jason.decode(json)

    conn
    |> render(%{result: body})
  end
end
