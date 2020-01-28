defmodule BoardrApi.DomainAssertions do
  alias Boardr.{Game, Player}

  import Asserter.Assertions

  import BoardrApi.Assertions,
    only: [assert_api_map: 1, assert_hal_curies: 1, assert_hal_embedded: 2, assert_hal_link: 3, assert_hal_links: 2]

  import BoardrApi.ConnCaseHelpers, only: [test_api_url: 1]

  def assert_game_resource(body, %Game{} = game, opts \\ []) do
    asserter = assert_api_map(body)

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
      |> assert_hal_link(
        "boardr:possible-actions",
        test_api_url("/games/#{game.id}/possible-actions")
      )
    end)

    # Properties
    |> assert_key("createdAt", DateTime.to_iso8601(game.created_at))
    |> assert_key("id", game.id)
    |> assert_key("rules", game.rules)
    |> assert_key("settings", game.settings)
    |> assert_key("state", game.state)
    |> assert_key("updatedAt", DateTime.to_iso8601(game.updated_at))

    if players = Keyword.get(opts, :players) do
      asserter
      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:players", fn embedded_players ->
          players
          |> Enum.reduce(
            assert_list(embedded_players),
            fn p, acc -> acc |> assert_next_member(&assert_player_resource(&1, p)) end
          )
          |> assert_no_more_members()
        end)
      end)
    else
      asserter
    end
  end

  def assert_player_resource(body, %Player{} = player) do
    assert_api_map(body)

    # HAL links
    |> assert_hal_links(fn links ->
      links
      |> assert_hal_curies()
      |> assert_hal_link("boardr:game", test_api_url("/games/#{player.game_id}"))
      |> assert_hal_link("boardr:user", test_api_url("/users/#{player.user_id}"))
      |> assert_hal_link("self", test_api_url("/games/#{player.game_id}/players/#{player.id}"))
    end)

    # Properties
    |> assert_key("createdAt", DateTime.to_iso8601(player.created_at))
    |> assert_key("number", player.number)
  end
end
