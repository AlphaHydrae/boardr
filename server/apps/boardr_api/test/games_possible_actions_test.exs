defmodule BoardrApi.GamesPossibleActionsTest do
  use BoardrApi.ConnCase

  alias Boardr.{Game, Player}

  require EEx
  EEx.function_from_string(:def, :api_path, "/api/games/<%= game.id %>/possible-actions", [:game])

  @all_board_positions 0..2
                       |> Enum.flat_map(fn col -> 0..2 |> Enum.map(fn row -> [col, row] end) end)

  setup do
    game = Fixtures.game(state: "playing")
    player1 = Fixtures.player(game: game)
    player2 = Fixtures.player(game: game, number: 2)

    %{
      game: game,
      player1: player1,
      player2: player2
    }
  end

  describe "GET /api/games/:gameId/possible-actions" do
    test "get possible actions in a fresh tic-tac-toe game", %{
      conn: %Conn{} = conn,
      game: game,
      player1: player1,
      test: test
    } do
      count_queries(test)

      # FIXME: check Location header
      body =
        conn
        |> get(api_path(game))
        |> json_response(200)

      # Response
      assert_possible_actions(body, game, player1, @all_board_positions)

      # Database changes
      assert_db_queries(select: 4)
    end

    test "get possible actions midway through a tic-tac-toe game", %{
      conn: %Conn{} = conn,
      game: game,
      player1: player1,
      player2: player2,
      test: test
    } do
      now = DateTime.utc_now()

      actions =
        [[0, 0], [2, 2], [2, 0], [1, 0], [1, 2]]
        |> Enum.with_index()
        |> Enum.map(fn {pos, i} ->
          Fixtures.action(
            game: game,
            performed_at: DateTime.add(now, i * 10 - 100, :second),
            player: if(rem(i, 2) == 0, do: player1, else: player2),
            position: pos
          )
        end)

      count_queries(test)

      # FIXME: check Location header
      body =
        conn
        |> get(api_path(game))
        |> json_response(200)

      # Response
      assert_possible_actions(
        body,
        game,
        player2,
        @all_board_positions -- Enum.map(actions, & &1.position)
      )

      # Database changes
      assert_db_queries(select: 4)
    end

    test "embed the game when retrieving possible actions", %{
      conn: %Conn{} = conn,
      game: game,
      player1: player1,
      test: test
    } do
      count_queries(test)

      # FIXME: check Location header
      body =
        conn
        |> get("#{api_path(game)}?embed=boardr:game")
        |> json_response(200)

      # Response
      assert_possible_actions(body, game, player1, @all_board_positions, embedded_game: true)

      # Database changes
      assert_db_queries(select: 4)
    end
  end

  defp assert_possible_actions(body, %Game{} = game, %Player{id: player_id}, positions, options \\ [])
       when is_list(positions) and is_list(options) do
    # Response
    %{result: %{possible_actions: possible_action_results}} =
      assert_api_map(body)

      # HAL links
      |> assert_hal_links(fn links ->
        links
        |> assert_hal_curies()
        |> assert_hal_link("self", test_api_url("/games/#{game.id}/possible-actions"))
      end)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded = embedded
        |> assert_key(
          "boardr:possible-actions",
          fn possible_actions ->
            positions
            |> Enum.reduce(assert_list(possible_actions), fn pos, acc ->
              acc |> assert_member(expected_possible_action(pos, game.id, player_id))
            end)
          end,
          into: :possible_actions
        )

        if Keyword.get(options, :embedded_game, false) do
          embedded
          |> assert_key(
            "boardr:game",
            &(assert_game_resource(&1, game))
          )
        else
          embedded
        end
      end)

    # FIXME: verify no more remaining members in asserter
    assert length(possible_action_results) == length(positions)
  end

  defp expected_possible_action([col, row], game_id, player_id)
       when is_integer(col) and is_integer(row) and is_binary(game_id) and is_binary(player_id) do
    %{
      "_links" => %{
        "boardr:game" => %{"href" => test_api_url("/games/#{game_id}")},
        "boardr:player" => %{"href" => test_api_url("/games/#{game_id}/players/#{player_id}")}
      },
      "position" => [col, row],
      "type" => "take"
    }
  end
end
