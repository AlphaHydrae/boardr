defmodule BoardrApi.GamesTest do
  use BoardrApi.ConnCase, async: true

  alias Boardr.{Game,Player}

  @api_path "/api/games"
  @valid_properties %{"rules" => "tic-tac-toe"}

  setup do
    %{
      user: Fixtures.user()
    }
  end

  setup :count_queries

  describe "POST /api/games" do
    test "create a game", %{
      conn: %Conn{} = conn,
      test_start: %DateTime{} = test_start,
      user: user
    } do
      # FIXME: check Location header
      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(user)}")
        |> post_json(@api_path, @valid_properties)
        |> json_response(201)

      # Response
      %{result: %{id: game_id, player: %{id: player_id} = expected_player} = expected_game} = assert_api_map(body)

        # HAL links
        |> assert_hal_links(fn links ->
          links
          |> assert_hal_curies()
          |> assert_hal_link("collection", test_api_url("/games"))
          |> assert_hal_link("boardr:creator", test_api_url_regex(["/users/", ~r/(?<creator_id>#{Regex.escape(user.id)})/]))
          |> assert_hal_link("self", test_api_url_regex(["/games/", ~r/(?<id>[\w-]+)/]))
          |> assert_hal_link("boardr:actions", fn %{id: game_id} -> test_api_url("/games/#{game_id}/actions") end)
          |> assert_hal_link("boardr:board", fn %{id: game_id} -> test_api_url("/games/#{game_id}/board") end)
          |> assert_hal_link("boardr:players", fn %{id: game_id} -> test_api_url("/games/#{game_id}/players") end)
          |> assert_hal_link("boardr:possible-actions", fn %{id: game_id} -> test_api_url("/games/#{game_id}/possible-actions") end)
        end)

        # Embedded HAL documents
        |> assert_hal_embedded(fn embedded ->
          embedded
          |> assert_key("boardr:player", fn player ->
            assert_map(player)
            |> assert_hal_links(fn links ->
              links
              |> assert_hal_curies()
              |> assert_hal_link("boardr:game", fn %{id: game_id} -> test_api_url_regex(["/games/", ~r/(?<game_id>#{Regex.escape(game_id)})/]) end)
              |> assert_hal_link("boardr:user", fn %{creator_id: user_id} -> test_api_url_regex(["/users/", ~r/(?<user_id>#{Regex.escape(user_id)})/]) end)
              |> assert_hal_link("self", fn %{id: game_id} -> test_api_url_regex(["/games/#{game_id}/players/", ~r/(?<id>[\w-]+)/]) end)
            end)
            |> assert_key("createdAt", &(&1.subject |> just_after(test_start)), into: :created_at)
            |> assert_key("number", 1)
            |> assert_key_absent("settings")
          end, into: :player)
        end)

        # Properties
        |> assert_keys(@valid_properties)
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key("settings", %{})
        |> assert_key_absent("state", value: "waiting_for_players")
        |> assert_key_absent("title")
        |> assert_key_identical("updatedAt", "createdAt")

      # Database changes
      assert_db_queries(insert: 2)
      assert_in_db(Game, game_id, expected_game)
      assert_in_db(Player, player_id, expected_player)
    end
  end
end