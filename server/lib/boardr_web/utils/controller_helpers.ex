defmodule BoardrWeb.ControllerHelpers do
  alias Plug.Conn

  import Phoenix.Controller, only: [render: 2]
  import Plug.Conn, only: [put_resp_content_type: 2]

  def render_hal(%Conn{} = conn, assigns) when is_map(assigns) do
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(assigns)
  end
end
