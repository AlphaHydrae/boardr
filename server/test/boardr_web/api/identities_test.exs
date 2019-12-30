defmodule BoardrWeb.IdentitiesTest do
  use BoardrWeb.ConnCase, async: true

  alias Boardr.Auth.Identity

  @api_path "/api/identities"
  @valid_properties %{"email" => "jdoe@example.com", "provider" => "local"}

  setup :count_queries

  describe "POST /api/identities" do
    test "create a local identity", %{conn: %Conn{} = conn, query_counter: query_counter} do
      now = DateTime.utc_now()

      body =
        conn
        |> post_json(@api_path, @valid_properties)
        |> json_response(201)

      assert %{
               "_embedded" => _embedded,
               "_links" => %{
                 "self" => %{ "href" => self_href }
               },
               "createdAt" => created_at,
               "emailVerified" => false,
               "lastAuthenticatedAt" => last_authenticated_at,
               "lastSeenAt" => last_seen_at,
               "providerId" => provider_id,
               "updatedAt" => updated_at
             } = body

      assert Map.take(body, ~w(email provider)) == @valid_properties
      assert provider_id == @valid_properties["email"]

      assert just_after?(created_at, now)
      assert created_at == updated_at

      assert just_after?(last_authenticated_at, now)
      assert last_authenticated_at == last_seen_at

      assert Map.keys(body) ==
               ~w(_embedded _links createdAt email emailVerified lastAuthenticatedAt lastSeenAt provider providerId updatedAt)

      assert query_counter |> counted_queries == %{insert: 1}

      id = self_href |> String.replace(~r/.*\//, "")
      assert Map.delete(Repo.get!(Identity, id), :__meta__) == Map.delete(%Identity{
        created_at: elem(DateTime.from_iso8601(created_at), 1),
        email: @valid_properties["email"],
        email_verified: false,
        email_verified_at: nil,
        id: id,
        last_authenticated_at: elem(DateTime.from_iso8601(last_authenticated_at), 1),
        last_seen_at: elem(DateTime.from_iso8601(last_seen_at), 1),
        provider: @valid_properties["provider"],
        provider_id: provider_id,
        updated_at: elem(DateTime.from_iso8601(updated_at), 1),
        user_id: nil
      }, :__meta__)
    end
  end

  defp just_after?(iso8601, t2) when is_binary(iso8601) do
    assert {:ok, t1, 0} = DateTime.from_iso8601(iso8601)
    just_after?(t1, t2)
  end

  defp just_after?(t1, t2) do
    diff = DateTime.diff(t1, t2, :microsecond)
    diff >= 0 and diff < 500_000
  end
end
