defmodule BoardrWeb.ApiController do
  use BoardrWeb, :controller

  def index(%Conn{} = conn, _params) do
    render(conn, :index)
  end
end
