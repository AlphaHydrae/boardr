defmodule BoardrWeb.ApiRootTest do
  use BoardrWeb.ConnCase, async: true

  @api_path "/api"

  setup :count_queries

  test "GET /api", %{conn: %Conn{} = conn, query_counter: query_counter} do
    body =
      conn
      |> get(@api_path)
      |> json_response(200)

    assert_map(body)

    # HAL links
    |> assert_hal_links(fn links ->
      links
      |> assert_hal_curies()
      |> assert_hal_link("boardr:games", test_api_url("/games"))
      |> assert_hal_link("boardr:identities", test_api_url("/identities"))
      |> assert_hal_link("boardr:users", test_api_url("/users"))
      |> assert_hal_link("self", test_api_url())
    end)

    # Properties
    |> assert_key("version", Application.spec(:boardr, :vsn) |> to_string)

    # Database changes
    assert_db_queries(query_counter, select: 0)
  end
end
