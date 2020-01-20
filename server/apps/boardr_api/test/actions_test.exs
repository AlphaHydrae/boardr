defmodule BoardrApi.ActionsTest do
  use BoardrApi.ConnCase

  alias Boardr.{Action, Game, Player}

  require EEx
  EEx.function_from_string(:def, :api_path, "/api/games/<%= game.id %>/actions", [:game])

  @valid_properties %{"type" => "take", "position" => [0, 0]}

  describe "POST /api/games/:gameId/actions" do
    setup [:create_playing_game, :count_queries]

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
        |> assert_key_absent("data")
        |> assert_key("performedAt", &(&1.subject |> just_after(test_start)))

      # Database changes
      assert_db_queries(insert: 1, max_transactions: 2, select: 4, update: 1)
      assert_in_db(Action, action_id, expected_action)

      # Make sure the game's state and last modification date were updated.
      updated_game = Repo.get!(Game, game.id)
      assert {:ok, _} = just_after(updated_game.updated_at, expected_action.performed_at)
      assert updated_game.state == "playing"
      assert Map.drop(game, [:creator, :state, :updated_at]) == Map.drop(updated_game, [:creator, :state, :updated_at])
    end
  end

  describe "with a game that is waiting for players" do
    setup [:create_waiting_game, :count_queries]

    test "POST /api/games/:gameId/actions returns an error", %{
      conn: %Conn{} = conn,
      game: game,
      first_player: %Player{user: user}
    } do
      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(user)}")
        |> post_json(api_path(game), @valid_properties)
        |> json_response(409)

      assert_api_map(body)
      |> assert_key("gameError", "game_not_started")
      |> assert_key("status", 409)
      |> assert_key("title", "The request cannot be completed due to a conflict with the current state of the resource.")
      |> assert_key("type", test_api_url("/problems/game-error"))
    end
  end

  describe "with a game that is finished" do
    setup [:create_finished_game, :count_queries]

    test "POST /api/games/:gameId/actions returns an error", %{
      conn: %Conn{} = conn,
      game: game,
      first_player: %Player{user: user}
    } do
      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_token!(user)}")
        |> post_json(api_path(game), @valid_properties)
        |> json_response(409)

      assert_api_map(body)
      |> assert_key("gameError", "game_finished")
      |> assert_key("status", 409)
      |> assert_key("title", "The request cannot be completed due to a conflict with the current state of the resource.")
      |> assert_key("type", test_api_url("/problems/game-error"))
    end
  end

  def create_finished_game(context) when is_map(context) do
    game = Fixtures.game(state: "draw")

    %{
      game: game,
      first_player: Fixtures.player(game: game),
      second_player: Fixtures.player(game: game, number: 2)
    }
  end

  def create_playing_game(context) when is_map(context) do
    game = Fixtures.game(state: "playing")

    %{
      game: game,
      first_player: Fixtures.player(game: game),
      second_player: Fixtures.player(game: game, number: 2)
    }
  end

  def create_waiting_game(context) when is_map(context) do
    game = Fixtures.game()

    %{
      game: game,
      first_player: Fixtures.player(game: game)
    }
  end
end
