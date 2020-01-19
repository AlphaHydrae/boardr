defmodule BoardrApi.IdentitiesTest do
  use BoardrApi.ConnCase

  alias Boardr.Auth.Identity

  @api_path "/api/identities"
  @valid_properties %{"email" => "jdoe@example.com", "provider" => "local"}

  describe "POST /api/identities" do
    setup [:clean_database, :count_queries]

    test "create a local identity", %{
      conn: %Conn{} = conn,
      test_start: %DateTime{} = test_start
    } do
      # FIXME: check Location header
      body =
        conn
        |> post_json(@api_path, @valid_properties)
        |> json_response(201)

      # Response
      %{result: %{id: identity_id, token: jwt_token} = expected_identity} =
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
          |> assert_key_absent("boardr:user", into: :user_id)
          |> assert_hal_link("collection", test_api_url("/identities"), %{}, into: false)
          |> assert_hal_link("self", test_api_url_regex(["/identities/", ~r/(?<id>[\w-]+)/]))
        end)

        # Properties
        |> assert_keys(@valid_properties)
        |> assert_key("createdAt", &(&1 |> just_after(test_start)), value: true)
        |> assert_key("emailVerified", false)
        |> assert_key_absent("emailVerifiedAt")
        |> assert_key("lastAuthenticatedAt", &(&1 |> just_after(test_start)), value: true)
        |> assert_key_identical("lastSeenAt", "lastAuthenticatedAt")
        |> assert_key_identical("providerId", "email")
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
      |> assert_key("scope", "register")
      |> assert_key("sub", identity_id)

      # Database changes
      assert_db_queries(insert: 1)
      assert_in_db(Identity, identity_id, expected_identity)
    end
  end
end
