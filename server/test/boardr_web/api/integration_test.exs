defmodule BoardrWeb.IntegrationTest.TestPlayer do
  defstruct email: nil, name: nil
end

defmodule BoardrWeb.IntegrationTest do
  use BoardrWeb.ConnCase

  alias BoardrWeb.IntegrationTest.TestPlayer

  @bob %TestPlayer{
    email: "bob@example.com",
    name: "bob"
  }

  @alice %TestPlayer{
    email: "alice@example.com",
    name: "alice"
  }

  @all_board_positions 0..2
                       |> Enum.flat_map(fn col -> 0..2 |> Enum.map(fn row -> {col, row} end) end)

  setup :count_queries

  test "play a winning tic-tac-toe game", %{
    conn: %Conn{} = conn
  } do
    conn
    |> register(@bob)
    |> register(@alice)
    # Create and join the game.
    |> create_game(@bob)
    |> check_game(state: "waiting_for_players", possible_actions: %{@bob => 0, @alice => 0})
    |> join_game(@alice)
    |> check_game(state: "playing", possible_actions: %{@bob => 9, @alice => 0})
    # Play the game.
    |> play(@bob, col: 1, row: 0)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 8})
    |> play(@alice, col: 1, row: 1)
    |> check_game(state: "playing", possible_actions: %{@bob => 7, @alice => 0})
    |> play(@bob, col: 2, row: 2)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 6})
    |> play(@alice, col: 2, row: 1)
    |> check_game(state: "playing", possible_actions: %{@bob => 5, @alice => 0})
    |> play(@bob, col: 0, row: 2)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 4})
    |> play(@alice, col: 0, row: 0)
    |> check_game(state: "playing", possible_actions: %{@bob => 3, @alice => 0})
    |> play(@bob, col: 1, row: 2)
    |> check_game(state: "win", possible_actions: %{@bob => 0, @alice => 0}, winners: [@bob])
  end

  test "play a tic-tac-toe game to a draw", %{
    conn: %Conn{} = conn
  } do
    conn
    |> register(@bob)
    |> register(@alice)
    # Create and join the game.
    |> create_game(@bob)
    |> check_game(state: "waiting_for_players", possible_actions: %{@bob => 0, @alice => 0})
    |> join_game(@alice)
    |> check_game(state: "playing", possible_actions: %{@bob => 9, @alice => 0})
    # Play the game.
    |> play(@bob, col: 2, row: 0)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 8})
    |> play(@alice, col: 1, row: 1)
    |> check_game(state: "playing", possible_actions: %{@bob => 7, @alice => 0})
    |> play(@bob, col: 1, row: 0)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 6})
    |> play(@alice, col: 0, row: 0)
    |> check_game(state: "playing", possible_actions: %{@bob => 5, @alice => 0})
    |> play(@bob, col: 2, row: 2)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 4})
    |> play(@alice, col: 2, row: 1)
    |> check_game(state: "playing", possible_actions: %{@bob => 3, @alice => 0})
    |> play(@bob, col: 0, row: 1)
    |> check_game(state: "playing", possible_actions: %{@bob => 0, @alice => 2})
    |> play(@alice, col: 1, row: 2)
    |> check_game(state: "playing", possible_actions: %{@bob => 1, @alice => 0})
    |> play(@bob, col: 0, row: 2)
    |> check_game(state: "draw", possible_actions: %{@bob => 0, @alice => 0})
  end

  @tag :slow
  test "randomly play 10 tic-tac-toe games to their conclusion", %{
    conn: %Conn{} = conn
  } do
    conn = conn
    |> register(@bob)
    |> register(@alice)

    for _ <- 1..10 do
      # Create and join the game.
      conn
      |> create_game(@bob)
      |> check_game(state: "waiting_for_players", possible_actions: %{@bob => 0, @alice => 0})
      |> join_game(@alice)
      # Play the game.
      |> play_until_finished()
    end
  end

  # Scenario functions

  defp register(%Conn{} = conn, %TestPlayer{email: email, name: name} = player) do
    assert %{"_embedded" => %{"boardr:token" => %{"value" => registration_token}}} =
             conn
             |> post_json("/api/identities", %{"email" => email, "provider" => "local"})
             |> json_response(201)

    assert %{"_embedded" => %{"boardr:token" => %{"value" => authentication_token}}} =
             conn
             |> put_req_header("authorization", "Bearer #{registration_token}")
             |> post_json("/api/users", %{"name" => name})
             |> json_response(201)

    conn
    |> assign_to(player, :token, authentication_token)
  end

  defp create_game(%Conn{} = conn, %TestPlayer{} = player) do
    assert %{
             "_embedded" => %{
               "boardr:player" => %{"_links" => %{"self" => %{"href" => player_url}}},
             },
             "_links" => %{
               "boardr:actions" => %{"href" => game_actions_url},
               "boardr:players" => %{"href" => game_players_url},
               "boardr:possible-actions" => %{"href" => game_possible_actions_url},
               "self" => %{"href" => game_url}
             }
           } =
             conn
             |> authenticate_as(player)
             |> post_json("/api/games", %{"rules" => "tic-tac-toe"})
             |> json_response(201)

    conn
    |> assign_to(player, :url, player_url)
    |> assign(:game_actions_url, game_actions_url)
    |> assign(:game_url, game_url)
    |> assign(:game_players_url, game_players_url)
    |> assign(:game_possible_actions_url, game_possible_actions_url)
  end

  defp join_game(%Conn{} = conn, %TestPlayer{} = player) do
    assert %{"_links" => %{"self" => %{"href" => player_url}}} =
             conn
             |> authenticate_as(player)
             |> post_json(conn.assigns[:game_players_url], %{})
             |> json_response(201)

    conn
    |> assign_to(player, :url, player_url)
  end

  defp check_game(%Conn{} = conn,
         state: "draw",
         possible_actions: expected_possible_actions
       ) do
    conn
    |> check_game_state("draw")
    |> check_game_possible_actions(expected_possible_actions)
  end

  defp check_game(%Conn{} = conn,
         state: "win",
         possible_actions: expected_possible_actions,
         winners: [%TestPlayer{} = winner]
       ) do
    conn
    |> check_game_state("win", winner)
    |> check_game_possible_actions(expected_possible_actions)
  end

  defp check_game(%Conn{} = conn,
         state: expected_state,
         possible_actions: expected_possible_actions
       ) do
    conn
    |> check_game_state(expected_state)
    |> check_game_possible_actions(expected_possible_actions)
  end

  defp play(%Conn{} = conn, %TestPlayer{} = player, position) do
    conn
    |> authenticate_as(player)
    |> post_json(conn.assigns[:game_actions_url], %{
      "type" => "take",
      "position" => [Keyword.get(position, :col), Keyword.get(position, :row)]
    })
    |> json_response(201)

    conn
  end

  def play_until_finished(%Conn{} = conn, remaining_positions \\ @all_board_positions) do
    current_player = if rem(length(remaining_positions), 2) == 1, do: @bob, else: @alice
    random_position = {col, row} = Enum.random(remaining_positions)

    body =
      %{"state" => state} =
      conn
      |> play(current_player, col: col, row: row)
      |> get_game_state()

    case state do
      "playing" ->
        assert get_in(body, ["_embedded", "boardr:winners"]) == nil
        assert length(remaining_positions) - 1 >= 1
        play_until_finished(conn, List.delete(remaining_positions, random_position))

      "draw" ->
        assert get_in(body, ["_embedded", "boardr:winners"]) == nil
        assert length(remaining_positions) - 1 == 0

      "win" ->
        assert %{
                 "_embedded" => %{
                   "boardr:winners" => [%{"_links" => %{"self" => %{"href" => winner_url}}}]
                 }
               } = body

        assert get_player_value(conn, current_player, :url) == winner_url
        assert length(remaining_positions) - 1 <= 4
    end
  end

  # Utility functions

  defp assign_to(%Conn{} = conn, %TestPlayer{} = player, key, value) do
    assign(conn, get_player_key(player, key), value)
  end

  defp authenticate_as(%Conn{} = conn, %TestPlayer{} = player) do
    conn
    |> put_req_header("authorization", "Bearer #{get_player_value(conn, player, :token)}")
  end

  defp check_game_possible_actions(
         %Conn{} = conn,
         %{
           @bob => expected_possible_actions_by_bob,
           @alice => expected_possible_actions_by_alice
         }
       )
       when is_integer(expected_possible_actions_by_bob) and
              is_integer(expected_possible_actions_by_alice) do
    assert %{"_embedded" => %{"boardr:possible-actions" => possible_actions}} =
             conn
             |> authenticate_as(@bob)
             |> get(conn.assigns[:game_possible_actions_url])
             |> json_response(200)

    possible_actions_by_bob = get_player_actions(conn, @bob, possible_actions)
    possible_actions_by_alice = get_player_actions(conn, @alice, possible_actions)

    assert length(possible_actions_by_bob) == expected_possible_actions_by_bob
    assert length(possible_actions_by_alice) == expected_possible_actions_by_alice

    assert length(possible_actions) ==
             expected_possible_actions_by_alice + expected_possible_actions_by_bob

    conn
  end

  defp check_game_state(%Conn{} = conn, expected_state, winner \\ nil)
       when is_binary(expected_state) do
    assert game = %{"state" => ^expected_state} = get_game_state(conn)

    if winner do
      winner_url = get_player_value(conn, winner, :url)

      assert [%{"_links" => %{"self" => %{"href" => ^winner_url}}}] =
               get_in(game, ["_embedded", "boardr:winners"])
    else
      assert get_in(game, ["_embedded", "boardr:winners"]) == nil
    end

    conn
  end

  defp get_game_state(%Conn{} = conn) do
    conn
    |> authenticate_as(@bob)
    |> get(conn.assigns[:game_url])
    |> json_response(200)
  end

  defp get_player_key(%TestPlayer{name: name}, key) do
    String.to_atom("#{name}_#{key}")
  end

  defp get_player_value(%Conn{} = conn, %TestPlayer{} = player, key) do
    conn.assigns[get_player_key(player, key)]
  end

  defp get_player_actions(%Conn{} = conn, %TestPlayer{} = player, actions)
       when is_list(actions) do
    player_url = get_player_value(conn, player, :url)

    Enum.filter(actions, fn action ->
      get_in(action, ["_links", "boardr:player", "href"]) == player_url
    end)
  end
end
