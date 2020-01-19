defmodule BoardrApi.GamesTest do
  use BoardrApi.ConnCase

  alias Boardr.{Game, Player}

  @api_path "/api/games"
  @valid_properties %{"rules" => "tic-tac-toe"}

  describe "POST /api/games" do
    setup [:create_user, :count_queries]

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
      %{result: %{id: game_id, player: %{id: player_id} = expected_player} = expected_game} =
        assert_api_map(body)

        # HAL links
        |> assert_hal_links(fn links ->
          links
          |> assert_hal_curies()
          |> assert_hal_link("collection", test_api_url("/games"))
          |> assert_hal_link(
            "boardr:creator",
            test_api_url_regex(["/users/", ~r/(?<creator_id>#{Regex.escape(user.id)})/])
          )
          |> assert_hal_link("self", test_api_url_regex(["/games/", ~r/(?<id>[\w-]+)/]))
          |> assert_hal_link("boardr:actions", fn %{id: game_id} ->
            test_api_url("/games/#{game_id}/actions")
          end)
          |> assert_hal_link("boardr:board", fn %{id: game_id} ->
            test_api_url("/games/#{game_id}/board")
          end)
          |> assert_hal_link("boardr:players", fn %{id: game_id} ->
            test_api_url("/games/#{game_id}/players")
          end)
          |> assert_hal_link("boardr:possible-actions", fn %{id: game_id} ->
            test_api_url("/games/#{game_id}/possible-actions")
          end)
        end)

        # Embedded HAL documents
        |> assert_hal_embedded(fn embedded ->
          embedded
          |> assert_key(
            "boardr:player",
            fn player ->
              assert_map(player)
              |> assert_hal_links(fn links ->
                links
                |> assert_hal_curies()
                |> assert_hal_link("boardr:game", fn %{id: game_id} ->
                  test_api_url_regex(["/games/", ~r/(?<game_id>#{Regex.escape(game_id)})/])
                end)
                |> assert_hal_link("boardr:user", fn %{creator_id: user_id} ->
                  test_api_url_regex(["/users/", ~r/(?<user_id>#{Regex.escape(user_id)})/])
                end)
                |> assert_hal_link("self", fn %{id: game_id} ->
                  test_api_url_regex(["/games/#{game_id}/players/", ~r/(?<id>[\w-]+)/])
                end)
              end)
              |> assert_key("createdAt", &(&1.subject |> just_after(test_start)),
                into: :created_at
              )
              |> assert_key("number", 1)
              |> assert_key_absent("settings")
            end,
            into: :player
          )
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

  describe "GET /api/games with no games" do
    setup [:create_user, :count_queries]

    test "retrieve an empty list", %{conn: %Conn{} = conn} do
      body =
        conn
        |> get(@api_path)
        |> json_response(200)

      # Response
      assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("self", test_api_url("/games"))
      end)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:games", [])
      end)
    end
  end

  describe "GET /api/games" do
    setup [:create_three_games, :count_queries]

    test "retrieve all games", %{conn: %Conn{} = conn, games: games} do
      body =
        conn
        |> get(@api_path)
        |> json_response(200)

      # Response
      assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("self", test_api_url("/games"))
      end)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:games", fn embedded_games ->
          assert_api_map(Enum.at(embedded_games.subject, 0))
          |> assert_game_resource(Enum.at(games, 2))

          assert_api_map(Enum.at(embedded_games.subject, 1))
          |> assert_game_resource(Enum.at(games, 1))

          assert_api_map(Enum.at(embedded_games.subject, 2))
          |> assert_game_resource(Enum.at(games, 0))

          assert length(embedded_games.subject) == 3

          embedded_games
        end)
      end)
    end

    test "retrieve games filtered by state", %{conn: %Conn{} = conn, games: games} do
      body =
        conn
        |> get("#{@api_path}?state=playing")
        |> json_response(200)

      # Response
      assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("self", test_api_url("/games"))
      end)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:games", fn embedded_games ->
          assert_api_map(Enum.at(embedded_games.subject, 0))
          |> assert_game_resource(Enum.at(games, 2))

          assert_api_map(Enum.at(embedded_games.subject, 1))
          |> assert_game_resource(Enum.at(games, 1))

          assert length(embedded_games.subject) == 2

          embedded_games
        end)
      end)
    end

    test "retrieve games filtered by player", %{
      conn: %Conn{} = conn,
      games: games,
      players: [_, player2 | _]
    } do
      body =
        conn
        |> get(
          "#{@api_path}?player=#{test_api_url("/games/#{player2.game_id}/players/#{player2.id}")}"
        )
        |> json_response(200)

      # Response
      assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("self", test_api_url("/games"))
      end)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:games", fn embedded_games ->
          assert_api_map(Enum.at(embedded_games.subject, 0))
          |> assert_game_resource(Enum.at(games, 1))

          assert length(embedded_games.subject) == 1

          embedded_games
        end)
      end)
    end

    test "retrieve no matching games", %{conn: %Conn{} = conn, players: [player1 | _]} do
      body =
        conn
        |> get(
          "#{@api_path}?player=#{test_api_url("/games/#{player1.game_id}/players/#{player1.id}")}&state=playing"
        )
        |> json_response(200)

      # Response
      assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("self", test_api_url("/games"))
      end)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:games", [])
      end)
    end
  end

  defp create_user(context) when is_map(context) do
    %{user: Fixtures.user()}
  end

  defp create_three_games(context) when is_map(context) do
    now = DateTime.utc_now()

    game1 = Fixtures.game(created_at: DateTime.add(now, -4 * 3600, :second))
    player1 = Fixtures.player(game: game1, user: game1.creator)

    game2 = Fixtures.game(created_at: DateTime.add(now, -3 * 3600, :second), state: "playing")
    player2 = Fixtures.player(game: game2, user: game2.creator)
    player3 = Fixtures.player(game: player2.game, number: 2)

    game3 = Fixtures.game(created_at: DateTime.add(now, -1 * 3600, :second), state: "playing")
    player4 = Fixtures.player(game: game3, user: game3.creator)
    player5 = Fixtures.player(game: game3, number: 2, user: game1.creator)

    %{
      games: [game1, game2, game3],
      players: [player1, player2, player3, player4, player5]
    }
  end
end
