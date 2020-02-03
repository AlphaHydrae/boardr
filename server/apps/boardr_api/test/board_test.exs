defmodule BoardrApi.BoardTest do
  use BoardrApi.ConnCase

  require EEx
  EEx.function_from_string(:def, :api_path, "/api/games/<%= game.id %>/board", [:game])

  setup do
    game = Fixtures.game(state: "playing")
    player1 = Fixtures.player(game: game)
    player2 = Fixtures.player(game: game, number: 2)

    %{
      game: game,
      players: [player1, player2]
    }
  end

  describe "GET /api/games/:gameId/board" do
    test "get an empty board for a fresh tic-tac-toe game", %{
      conn: %Conn{} = conn,
      game: game,
      test: test
    } do
      count_queries(test)

      # FIXME: check Location header
      body =
        conn
        |> get(api_path(game))
        |> json_response(200)

      # Response
      assert_api_map(body)

      # Properties
      |> assert_key("data", [])
      |> assert_key("dimensions", [3, 3])

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("boardr:game", test_api_url("/games/#{game.id}"))
        |> assert_hal_link("self", test_api_url("/games/#{game.id}/board"))
      end)

      # Database changes
      assert_db_queries(select: 4)
    end

    test "get the board in an ongoing tic-tac-toe game", %{
      conn: %Conn{} = conn,
      game: game,
      players: [player1, player2],
      test: test
    } do
      Fixtures.action(game: game, player: player1, position: [0, 0])
      Fixtures.action(game: game, player: player2, position: [0, 1])
      Fixtures.action(game: game, player: player1, position: [1, 1])
      Fixtures.action(game: game, player: player2, position: [2, 2])
      count_queries(test)

      # FIXME: check Location header
      body =
        conn
        |> get(api_path(game))
        |> json_response(200)

      # Response
      assert_api_map(body)

      # Properties
      |> assert_key("data", fn data ->
        assert_list(data)
        |> assert_member(%{"player" => 1, "position" => [0, 0]})
        |> assert_member(%{"player" => 2, "position" => [0, 1]})
        |> assert_member(%{"player" => 1, "position" => [1, 1]})
        |> assert_member(%{"player" => 2, "position" => [2, 2]})
        |> assert_no_more_members()
      end)
      |> assert_key("dimensions", [3, 3])

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("boardr:game", test_api_url("/games/#{game.id}"))
        |> assert_hal_link("self", test_api_url("/games/#{game.id}/board"))
      end)

      # Database changes
      assert_db_queries(select: 4)
    end
  end
end
