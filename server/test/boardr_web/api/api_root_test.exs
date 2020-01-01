defmodule BoardrWeb.ApiRootTest do
  use BoardrWeb.ConnCase, async: true

  @api_path "/api"

  test "GET /api", %{conn: %Conn{} = conn} do
    body =
      conn
      |> get(@api_path)
      |> json_response(200)

    assert_map(body)
    |> assert_key("_links", fn links ->
      assert_map(links)
      |> assert_hal_curies()
      |> assert_hal_link("boardr:games", test_api_url("/games"))
      |> assert_hal_link("boardr:identities", test_api_url("/identities"))
      |> assert_hal_link("boardr:users", test_api_url("/users"))
      |> assert_hal_link("self", test_api_url())
    end)
    |> assert_key("version", Application.spec(:boardr, :vsn) |> to_string)
  end
end
