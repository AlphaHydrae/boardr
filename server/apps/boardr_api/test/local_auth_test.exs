defmodule BoardrApi.LocalAuthTest do
  use BoardrApi.ConnCase

  alias Boardr.Auth.{Identity, User}

  @api_path "/api/auth/local"
  @valid_properties %{"email" => "jdoe@boardr.local"}

  setup do
    %{
      identity: Fixtures.identity(
        email: @valid_properties["email"],
        user: Fixtures.user()
      )
    }
  end

  setup :count_queries

  test "POST /api/auth/local produces a valid JWT", %{
    conn: %Conn{} = conn,
    identity: %Identity{user: %User{id: user_id} = user},
    test_start: %DateTime{} = test_start
  } do
    body =
      conn
      |> post_json(@api_path, @valid_properties)
      |> json_response(200)

    # Response
    %{result: %{token: jwt_token}} =
      assert_api_map(body)

      # Embedded HAL documents
      |> assert_hal_embedded(fn embedded ->
        embedded
        |> assert_key("boardr:token", fn token ->
          assert_map(token)
          |> assert_key("value", ~r/^[^.]+\.[^.]+\.[^.]+$/, into: :token)
        end)
        |> assert_key("boardr:user", &assert_user_resource(&1, user))
      end)

    # JWT token
    claims = verify_jwt_token!(jwt_token)
    truncated_test_start = DateTime.truncate(test_start, :second)
    expected_expiration = DateTime.add(truncated_test_start, 3600 * 24 * 7, :second)

    assert_map(claims)
    |> assert_key("aud", "boardr.alphahydrae.io")
    |> assert_key("exp", &(&1.subject |> just_after(expected_expiration)))
    |> assert_key("jti", ~r/^\w+$/)
    |> assert_key("iat", &(&1.subject |> just_after(truncated_test_start)))
    |> assert_key("iss", "boardr.alphahydrae.io")
    |> assert_key("scope", "api")
    |> assert_key("sub", "u:#{user_id}")

    # Database changes
    assert_db_queries(select: 1)
  end
end
