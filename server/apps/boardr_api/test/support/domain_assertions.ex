defmodule BoardrApi.DomainAssertions do
  alias Boardr.Game

  import Asserter.Assertions
  import BoardrApi.Assertions, only: [assert_api_map: 1, assert_hal_curies: 1, assert_hal_link: 3, assert_hal_links: 2]
  import BoardrApi.ConnCaseHelpers, only: [test_api_url: 1]

  def assert_game_resource(body, %Game{} = game) do
    assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("collection", test_api_url("/games"))
        |> assert_hal_link("boardr:creator", test_api_url("/users/#{game.creator_id}"))
        |> assert_hal_link("self", test_api_url("/games/#{game.id}"))
        |> assert_hal_link("boardr:actions", test_api_url("/games/#{game.id}/actions"))
        |> assert_hal_link("boardr:board", test_api_url("/games/#{game.id}/board"))
        |> assert_hal_link("boardr:players", test_api_url("/games/#{game.id}/players"))
        |> assert_hal_link("boardr:possible-actions", test_api_url("/games/#{game.id}/possible-actions"))
      end)

      # Properties
      |> assert_key("createdAt", DateTime.to_iso8601(game.created_at))
      |> assert_key("rules", game.rules)
      |> assert_key("settings", game.settings)
      |> assert_key("state", game.state)
      |> assert_key("updatedAt", DateTime.to_iso8601(game.updated_at))
  end
end
