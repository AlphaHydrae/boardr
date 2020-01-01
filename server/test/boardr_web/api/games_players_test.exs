defmodule BoardrWeb.GamesPlayersTest do
  use BoardrWeb.ConnCase, async: true

  alias Boardr.Player

  require EEx
  EEx.function_from_string(:def, :api_path, "/api/games/<%= game.id %>/players", [:game])

  setup do
    %{
      game: Fixtures.game(),
      user: Fixtures.user()
    }
  end

  describe "POST /api/games/:gameId/players" do
    test "join a tic-tac-toe game", %{
      conn: %Conn{} = conn,
      game: game,
      test: test,
      test_start: %DateTime{} = test_start,
      user: user
    } do
      query_counter = count_queries(test)

      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(user)}")
        |> post_json(api_path(game), %{})
        |> json_response(201)

      %{result: %{id: player_id} = expected_player} =
        assert_api_map(body)

        # HAL links
        |> assert_hal_links(fn links ->
          links
          |> assert_hal_curies()
          |> assert_hal_link(
            "boardr:game",
            test_api_url_regex(["/games/", ~r/(?<game_id>#{Regex.escape(game.id)})/])
          )
          |> assert_hal_link(
            "boardr:user",
            test_api_url_regex(["/users/", ~r/(?<user_id>#{Regex.escape(user.id)})/])
          )
          |> assert_hal_link(
            "self",
            test_api_url_regex(["/games/#{game.id}/players/", ~r/(?<id>[\w-]+)/])
          )
        end)

        # Properties
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key("number", 1)

      # Database changes
      assert_db_queries(query_counter,
        insert: 1
      )

      assert_in_db(Player, player_id, expected_player)
    end

    test "join a tic-tac-toe game as the second player", %{
      conn: %Conn{} = conn,
      game: game,
      test: test,
      test_start: %DateTime{} = test_start,
      user: user
    } do
      # Create the first player.
      Fixtures.player(game: game, user: user)

      # Create the user who will be the second player.
      other_user = Fixtures.user()

      query_counter = count_queries(test)

      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(other_user)}")
        |> post_json(api_path(game), %{})
        |> json_response(201)

      %{result: %{id: player_id} = expected_player} =
        assert_api_map(body)

        # HAL links
        |> assert_hal_links(fn links ->
          links
          |> assert_hal_curies()
          |> assert_hal_link(
            "boardr:game",
            test_api_url_regex(["/games/", ~r/(?<game_id>#{Regex.escape(game.id)})/])
          )
          |> assert_hal_link(
            "boardr:user",
            test_api_url_regex(["/users/", ~r/(?<user_id>#{Regex.escape(other_user.id)})/])
          )
          |> assert_hal_link(
            "self",
            test_api_url_regex(["/games/#{game.id}/players/", ~r/(?<id>[\w-]+)/])
          )
        end)

        # Properties
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key("number", 2)

      # Database changes
      assert_db_queries(query_counter,
        insert: 1
      )

      assert_in_db(Player, player_id, expected_player)
    end
  end
end
