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

  setup :count_queries

  test "play winning tic-tac-toe game with bob and alice", %{
    conn: %Conn{} = conn
  } do
    conn
    |> register(@bob)
    |> register(@alice)
    |> create_game(@bob)
    |> join_game(@bob)
    |> join_game(@alice)

    |> check_possible_actions(@bob, 9)
    |> play(@bob, col: 1, row: 0)

    |> check_possible_actions(@alice, 8)
    |> play(@alice, col: 1, row: 1)

    |> check_possible_actions(@bob, 7)
    |> check_possible_actions(@alice, 7)
    |> play(@bob, col: 2, row: 2)

    |> check_possible_actions(@alice, 6)
    |> play(@alice, col: 2, row: 1)

    |> check_possible_actions(@bob, 5)
    |> check_possible_actions(@alice, 5)
    |> play(@bob, col: 0, row: 2)

    |> check_possible_actions(@alice, 4)
    |> play(@alice, col: 0, row: 0)

    |> check_possible_actions(@bob, 3)
    |> play(@bob, col: 1, row: 2)

    |> check_possible_actions(@bob, 0)
    |> check_possible_actions(@alice, 0)

    # TODO: check winners
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
    |> assign_to(player, "token", authentication_token)
  end

  defp create_game(%Conn{} = conn, %TestPlayer{} = player) do
    assert %{
             "_links" => %{
               "boardr:actions" => %{"href" => game_actions_url},
               "boardr:players" => %{"href" => game_players_url},
               "boardr:possible-actions" => %{"href" => game_possible_actions_url}
             }
           } =
             conn
             |> authenticate_as(player)
             |> post_json("/api/games", %{"rules" => "tic-tac-toe"})
             |> json_response(201)

    conn
    |> assign(:game_actions_url, game_actions_url)
    |> assign(:game_players_url, game_players_url)
    |> assign(:game_possible_actions_url, game_possible_actions_url)
  end

  defp join_game(%Conn{} = conn, %TestPlayer{} = player) do
    conn
    |> authenticate_as(player)
    |> post_json(conn.assigns[:game_players_url], %{})
    |> json_response(201)

    conn
  end

  defp check_possible_actions(%Conn{} = conn, %TestPlayer{} = player, expected) when is_integer(expected) do
    assert %{"_embedded" => %{"boardr:possible-actions" => possible_actions}} = conn
    |> authenticate_as(player)
    |> get(conn.assigns[:game_possible_actions_url])
    |> json_response(200)

    assert length(possible_actions) == expected

    conn
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

  # Utility functions

  defp assign_to(%Conn{} = conn, %TestPlayer{} = player, key, value) do
    assign(conn, get_test_player_key(player, key), value)
  end

  defp authenticate_as(%Conn{} = conn, %TestPlayer{} = player) do
    conn
    |> put_req_header("authorization", "Bearer #{get_test_player_value(conn, player, :token)}")
  end

  defp get_test_player_key(%TestPlayer{name: name}, key) do
    String.to_atom("#{name}_#{key}")
  end

  defp get_test_player_value(%Conn{} = conn, %TestPlayer{} = player, key) do
    conn.assigns[get_test_player_key(player, key)]
  end
end
