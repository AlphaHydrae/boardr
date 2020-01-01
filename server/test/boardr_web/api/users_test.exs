defmodule BoardrWeb.UsersTest do
  use BoardrWeb.ConnCase, async: true

  alias Boardr.Auth.{Identity, User}

  @api_path "/api/users"
  @valid_properties %{"name" => "jdoe"}

  setup do
    %{
      identity: Fixtures.identity()
    }
  end

  setup :count_queries

  describe "POST /api/users" do
    test "create a user account", %{
      conn: %Conn{} = conn,
      identity: identity,
      test_start: %DateTime{} = test_start
    } do
      body =
        conn
        |> put_req_header("authorization", "Bearer #{generate_registration_token!(identity)}")
        |> post_json(@api_path, @valid_properties)
        |> json_response(201)

      # Response
      %{result: %{id: user_id, token: jwt_token} = expected_user} =
        assert_api_map(body)

        # Embedded HAL documents
        |> assert_hal_embedded(fn embedded ->
          embedded
          |> assert_key("boardr:token", fn token ->
            assert_map(token)
            |> assert_key("value", ~r/^[^.]+\.[^.]+\.[^.]+$/, into: :token)
          end)
        end)

        # HAL links
        |> assert_hal_links(fn links ->
          links
          |> assert_hal_curies()
          |> assert_hal_link("self", test_api_url_regex(["/users/", ~r/(?<id>[\w-]+)/]))
        end)

        # Properties
        |> assert_keys(@valid_properties)
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key_identical("updatedAt", "createdAt")

      # JWT token
      claims = verify_jwt_token!(jwt_token)
      truncated_test_start = DateTime.truncate(test_start, :second)
      expected_expiration = DateTime.add(truncated_test_start, 3600 * 24 * 7, :second)

      assert_map(claims)
      |> assert_key("aud", "boardr.alphahydrae.io")
      |> assert_key("exp", &(&1 |> just_after(expected_expiration)), value: true)
      |> assert_key("jti", ~r/^\w+$/)
      |> assert_key("iat", &(&1 |> just_after(truncated_test_start)), value: true)
      |> assert_key("iss", "boardr.alphahydrae.io")
      |> assert_key("nbf", &(&1 |> just_after(truncated_test_start)), value: true)
      |> assert_key("scope", "api")
      |> assert_key("sub", user_id)

      # Database changes
      assert_db_queries(insert: 1, update: 1)
      assert_in_db(User, user_id, expected_user)
    end
  end

  def generate_registration_token!(%Identity{id: identity_id}) do
    {:ok, token} =
      Boardr.Auth.Token.generate(%{
        scope: "register",
        sub: identity_id
      })

    token
  end
end
