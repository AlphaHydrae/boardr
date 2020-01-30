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

        # Properties
        |> assert_keys(@valid_properties)
        |> assert_key("createdAt", &(&1.subject |> just_after(test_start)))
        |> assert_key("emailVerified", false)
        |> assert_key_absent("emailVerifiedAt")
        |> assert_key("id", &is_binary(&1.subject))
        |> assert_key("lastAuthenticatedAt", &(&1.subject |> just_after(test_start)))
        |> assert_key_identical("lastSeenAt", "lastAuthenticatedAt")
        |> assert_key_identical("providerId", "email")
        |> assert_key_identical("updatedAt", "createdAt")

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
          |> assert_hal_link("self", fn %{id: identity_id} -> test_api_url("/identities/#{identity_id}") end)
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
      |> assert_key("nbf", &(&1.subject |> just_after(truncated_test_start)))
      |> assert_key("scope", "register")
      |> assert_key("sub", "i:#{identity_id}")

      # Database changes
      assert_db_queries(insert: 1)
      assert_in_db(Identity, identity_id, expected_identity)
    end
  end

  describe "POST /api/identities with an existing identity" do
    setup [:clean_database, :create_identity, :count_queries]

    test "a duplicate local entity cannot be created", %{
      conn: %Conn{} = conn
    } do
      body =
        conn
        |> post_json(@api_path, @valid_properties)
        |> json_response(422)

      # Response
      assert_api_map(body)
      |> assert_key("errors", fn errors ->
        assert_list(errors)
        |> assert_member(%{"message" => "has already been taken", "property" => "/provider_id"})
        |> assert_no_more_members()
      end)
      |> assert_key("status", 422)
      |> assert_key("title", "The request body contains invalid properties.")
      |> assert_key("type", test_api_url("/problems/validation-error"))

      # Database changes
      assert_db_queries(insert: 0, select: 0)
    end
  end

  defp create_identity(context) when is_map(context) do
    Map.put(
      context,
      :identity,
      Fixtures.identity(
        email: @valid_properties["email"],
        provider: @valid_properties["local"]
      )
    )
  end
end
