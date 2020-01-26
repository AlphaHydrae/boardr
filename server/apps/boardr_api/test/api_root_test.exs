defmodule BoardrApi.ApiRootTest do
  use BoardrApi.ConnCase, async: true

  @api_path "/api"

  setup :count_queries

  test "GET /api", %{conn: %Conn{} = conn} do
    body =
      conn
      |> get(@api_path)
      |> json_response(200)

    # Response
    assert_map(body)

    # HAL links
    |> assert_hal_links(fn links ->
      links
      |> assert_hal_curies()
      |> assert_hal_link("boardr:game", test_api_url("/games/{id}"), %{"templated" => true})
      |> assert_hal_link("boardr:games", test_api_url("/games"))
      |> assert_hal_link("boardr:identities", test_api_url("/identities"))
      |> assert_hal_link("boardr:users", test_api_url("/users"))
      |> assert_hal_link("self", test_api_url())
    end)

    # Properties
    |> assert_key("version", Application.spec(:boardr, :vsn) |> to_string)

    # Database changes
    assert_db_queries(select: 0)
  end
end
