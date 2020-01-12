defmodule BoardrApi.ActionsTest do
  use BoardrApi.ConnCase

  alias Boardr.{Action, Game, Player}

  require EEx
  EEx.function_from_string(:def, :api_path, "/api/games/<%= game.id %>/actions", [:game])

  @valid_properties %{"type" => "take", "position" => [0, 0]}

  setup do
    game = Fixtures.game(state: "playing")

    %{
      game: game,
      first_player: Fixtures.player(game: game),
      second_player: Fixtures.player(game: game, number: 2)
    }
  end

  describe "POST /api/games/:gameId/actions" do
    setup :count_queries

    test "play the first move in a tic-tac-toe game", %{
      conn: %Conn{} = conn,
      game: game,
      first_player: %Player{user: user} = first_player,
      test_start: %DateTime{} = test_start
    } do
      # FIXME: check Location header
      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(user)}")
        |> post_json(api_path(game), @valid_properties)
        |> json_response(201)

      # Response
      %{result: %{id: action_id} = expected_action} =
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
            "boardr:player",
            test_api_url_regex([
              "/games/#{game.id}/players/",
              ~r/(?<player_id>#{Regex.escape(first_player.id)})/
            ])
          )
          |> assert_hal_link("collection", test_api_url("/games/#{game.id}/actions"))
          |> assert_hal_link(
            "self",
            test_api_url_regex(["/games/#{game.id}/actions/", ~r/(?<id>[\w-]+)/])
          )
        end)

        # Properties
        |> assert_keys(@valid_properties)
        |> assert_key("performedAt", &(&1.subject |> just_after(test_start)))

      # Database changes
      assert_db_queries(insert: 1, max_selects: 6, max_transactions: 2, update: 1)
      assert_in_db(Action, action_id, expected_action)

      # Make sure the game's state and last modification date were updated.
      updated_game = Repo.get!(Game, game.id)
      assert {:ok, _} = just_after(updated_game.updated_at, expected_action.performed_at)
      assert updated_game.state == "playing"
      assert Map.drop(game, [:state, :updated_at]) == Map.drop(updated_game, [:state, :updated_at])
    end
  end
end
