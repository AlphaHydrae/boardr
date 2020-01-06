defmodule BoardrApi.ApiRootController do
  use BoardrApi, :controller

  def index(%Conn{} = conn, _params) do
    render(conn, :index)
  end
end
