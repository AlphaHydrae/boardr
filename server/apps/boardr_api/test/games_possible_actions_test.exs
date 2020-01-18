defmodule BoardrApi.GamesPossibleActionsTest do
  use BoardrApi.ConnCase

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
          embedded
          |> assert_key(
            "boardr:possible-actions",
            fn possible_actions ->
              @all_board_positions
              |> Enum.reduce(assert_list(possible_actions), fn pos, acc ->
                acc |> assert_member(expected_possible_action(pos, game.id, player1.id))
              end)
            end,
            into: :possible_actions
          )
        end)

      # FIXME: verify no more remaining members in asserter
      assert length(possible_action_results) == 9

      # Database changes
      assert_db_queries(max_selects: 6)
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
        [[0, 0], [2, 2], [2, 0], [1, 0]]
        |> Enum.with_index()
        |> Enum.map(fn {pos, i} ->
          Fixtures.action(
            performed_at: DateTime.add(now, i * 10 + -60, :second),
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
          embedded
          |> assert_key(
            "boardr:possible-actions",
            fn possible_actions ->
              assert_list(possible_actions)

              (@all_board_positions -- Enum.map(actions, & &1.position))
              |> Enum.reduce(assert_list(possible_actions), fn pos, acc ->
                acc |> assert_member(expected_possible_action(pos, game.id, player1.id))
              end)
            end,
            into: :possible_actions
          )
        end)

      # FIXME: verify no more remaining members in asserter
      assert length(possible_action_results) == 5

      # Database changes
      assert_db_queries(max_selects: 6)
    end
  end

  defp expected_possible_action([col, row], game_id, player_id)
       when is_integer(col) and is_integer(row) and is_binary(game_id) and is_binary(player_id) do
    %{
      "_links" => %{
        "boardr:game" => %{"href" => test_api_url("/games/#{game_id}")},
        "boardr:player" => %{"href" => test_api_url("/games/#{game_id}/players/#{player_id}")}
      },
      "position" => [0, 0],
      "type" => "take"
    }
  end
end
