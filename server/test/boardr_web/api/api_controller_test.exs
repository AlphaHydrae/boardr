defmodule BoardrWeb.ApiControllerTest do
  use BoardrWeb.ConnCase, async: true

  @api_path "/api"

  test "GET /api", %{conn: %Conn{} = conn} do
    body = conn |> get(@api_path) |> json_response(200)

    assert body ==
             api_document()
             |> put_property(:version, Application.spec(:boardr, :vsn) |> to_string)
             |> put_link(:'boardr:games', test_api_url("/games"))
             |> put_link(:'boardr:identities', test_api_url("/identities"))
             |> put_link(:'boardr:users', test_api_url("/users"))
             |> put_link(:self, test_api_url())
             |> HalDocument.to_map()
  end
end
