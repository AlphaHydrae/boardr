defmodule BoardrApi.GamesPlayersTest do
  use BoardrApi.ConnCase

  alias Boardr.{Game, Player}

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
      count_queries(test)

      # FIXME: check Location header
      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(user)}")
        |> post_json(api_path(game), %{})
        |> json_response(201)

      # Response
      %{result: %{id: player_id} = expected_player} =
        assert_api_map(body)

        # Properties
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key("id", &is_binary(&1.subject))
        |> assert_key("number", 1)
        |> assert_key_absent("settings")

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
            fn %{id: player_id} -> test_api_url("/games/#{game.id}/players/#{player_id}") end
          )
        end)

      # Database changes
      assert_db_queries(insert: 1, max_transactions: 2, select: 4)
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

      count_queries(test)

      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(other_user)}")
        |> post_json(api_path(game), %{})
        |> json_response(201)

      # Response
      %{result: %{id: player_id} = expected_player} =
        assert_api_map(body)

        # Properties
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key("id", &is_binary(&1.subject))
        |> assert_key("number", 2)
        |> assert_key_absent("settings")

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
            fn %{id: player_id} -> test_api_url("/games/#{game.id}/players/#{player_id}") end
          )
        end)

      # Database changes
      assert_db_queries(insert: 1, max_transactions: 2, select: 4, update: 1)
      assert_in_db(Player, player_id, expected_player)

      # Make sure the game's state and last modification date were updated.
      updated_game = Repo.get!(Game, game.id)
      assert {:ok, _} = just_after(updated_game.updated_at, expected_player.created_at)
      assert updated_game.state == "playing"

      assert Map.drop(game, [:creator, :state, :updated_at]) ==
               Map.drop(updated_game, [:creator, :state, :updated_at])
    end

    test "a tic-tac-toe game that has already started cannot be joined", %{
      conn: %Conn{} = conn,
      game: game,
      test: test,
      user: user
    } do
      # Create the first and second players.
      Fixtures.player(game: game, user: user)
      Fixtures.player(game: game, number: 2, user: Fixtures.user())

      game =
        game
        |> Game.changeset(%{state: "playing"})
        |> Repo.update!()

      # Create the user who will attempt to join the game.
      other_user = Fixtures.user()

      count_queries(test)

      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(other_user)}")
        |> post_json(api_path(game), %{})
        |> json_response(409)

      # Response
      assert_api_map(body)
      |> assert_key("gameError", "game_already_started")
      |> assert_key("status", 409)
      |> assert_key(
        "title",
        "The request cannot be completed due to a conflict with the current state of the resource."
      )
      |> assert_key("type", test_api_url("/problems/game-error"))

      # Database changes
      assert_db_queries(select: 4)
    end
  end
end
