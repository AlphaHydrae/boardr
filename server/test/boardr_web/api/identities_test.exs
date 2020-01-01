defmodule BoardrWeb.IdentitiesTest do
  use BoardrWeb.ConnCase, async: true

  alias Boardr.Auth.Identity

  use Asserter
  import BoardrWeb.Assertions

  @api_path "/api/identities"
  @valid_properties %{"email" => "jdoe@example.com", "provider" => "local"}

  setup :count_queries

  describe "POST /api/identities" do
    test "create a local identity", %{
      conn: %Conn{} = conn,
      query_counter: query_counter,
      test_start: %DateTime{} = test_start
    } do
      body =
        conn
        |> post_json(@api_path, @valid_properties)
        |> json_response(201)

      %{result: %{id: identity_id, token: jwt_token} = expected_identity} = assert_api_map(body)

        # Embedded HAL documents
        |> assert_key("_embedded", fn embedded ->
          assert_map(embedded)
          |> assert_key("boardr:token", fn token ->
            assert_map(token)
            |> assert_key("value", ~r/^[^.]+\.[^.]+\.[^.]+$/, into: :token)
          end)
        end, merge: true)

        # HAL links
        |> assert_key("_links", fn links ->
          assert_map(links)
          |> assert_key_absent("boardr:user", into: :user_id)
          |> assert_key("collection", &(&1 |> assert_hal_link(test_api_url("/identities"), %{}, into: false)))
          |> assert_key("self", &(&1 |> assert_hal_link(test_api_url_regex(["/identities/", ~r/(?<id>[\w-]+)/]))))
        end, merge: true)

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
      |> ignore_keys(["exp"])

      # Database changes
      assert query_counter |> counted_queries == %{insert: 1}
      assert_in_db Identity, identity_id, expected_identity
    end
  end

  def just_after(unix_timestamp, %DateTime{} = t2) when is_integer(unix_timestamp) do
    case DateTime.from_unix(unix_timestamp, :second) do
      {:ok, t1} -> just_after(t1, t2)
      _ -> {:nok, [message: "is not a Unix timestamp", expected_just_after: t2]}
    end
  end

  def just_after(iso8601, %DateTime{} = t2) when is_binary(iso8601) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, t1, 0} -> just_after(t1, t2)
      {:ok, _, _} -> {:nok, [message: "is not UTC", expected_just_after: t2]}
      _ -> {:nok, [message: "is not a valid ISO-8601 date", expected_just_after: t2]}
    end
  end

  def just_after(%DateTime{} = t1, %DateTime{} = t2) do
    diff = DateTime.diff(t1, t2, :microsecond)
    cond do
      diff < 0 -> {:nok, [message: "is before #{inspect(t2)}", expected_just_after: t2]}
      diff > 500_000 -> {:nok, [message: "is more than 500ms after #{inspect(t2)}", expected_just_after: t2]}
      true -> {:ok, t1}
    end
  end
end
