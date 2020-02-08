defmodule BoardrApi.ApiRootController do
  use BoardrApi, :controller

  def index(%Conn{} = conn, _params) do
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(:index)
  end
end
