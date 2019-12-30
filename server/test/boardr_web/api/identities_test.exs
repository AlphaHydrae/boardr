defmodule BoardrWeb.IdentitiesTest do
  use BoardrWeb.ConnCase, async: true

  alias Boardr.Auth.Identity

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

      assert %{
               "_embedded" => _embedded,
               "createdAt" => created_at,
               "emailVerified" => false,
               "lastAuthenticatedAt" => last_authenticated_at,
               "lastSeenAt" => last_seen_at,
               "providerId" => provider_id,
               "updatedAt" => updated_at
             } = body

      %{self: %{"id" => identity_id}} =
        assert body
               |> has_links?(
                 collection: test_api_url("/identities"),
                 self: test_api_url_regex(["/identities/", ~r/(?<id>[\w-]+)/])
               )

      # Check properties.
      assert Map.take(body, Map.keys(@valid_properties)) == @valid_properties
      assert provider_id == @valid_properties["email"]

      # Check timestamps.
      assert just_after?(created_at, test_start)
      assert created_at == updated_at

      # Check authentication timestamps.
      assert just_after?(last_authenticated_at, test_start)
      assert last_authenticated_at == last_seen_at

      assert Map.keys(body) ==
               ~w(_embedded _links createdAt email emailVerified lastAuthenticatedAt lastSeenAt provider providerId updatedAt)

      assert query_counter |> counted_queries == %{insert: 1}

      assert Map.delete(Repo.get!(Identity, identity_id), :__meta__) ==
               Map.delete(
                 %Identity{
                   created_at: elem(DateTime.from_iso8601(created_at), 1),
                   email: @valid_properties["email"],
                   email_verified: false,
                   email_verified_at: nil,
                   id: identity_id,
                   last_authenticated_at: elem(DateTime.from_iso8601(last_authenticated_at), 1),
                   last_seen_at: elem(DateTime.from_iso8601(last_seen_at), 1),
                   provider: @valid_properties["provider"],
                   provider_id: provider_id,
                   updated_at: elem(DateTime.from_iso8601(updated_at), 1),
                   user_id: nil
                 },
                 :__meta__
               )
    end
  end

  def has_links?(body, expected_links) when is_map(body) and is_list(expected_links) do
    links = body["_links"]

    result =
      expected_links
      |> Keyword.keys()
      |> Enum.reduce(%{}, fn rel, acc ->
        Map.put(acc, rel, assert(links |> has_link?(rel, Keyword.get(expected_links, rel))))
      end)

    expected_link_rels = expected_links |> Keyword.keys() |> Enum.map(&Atom.to_string/1)
    assert links == Map.take(links, expected_link_rels)
    result
  end

  def has_links?(_body, expected_links) when is_list(expected_links) do
    false
  end

  def has_link?(links, rel, href, link_properties \\ %{})

  def has_link?(links, rel, href, link_properties)
      when is_atom(rel) and is_binary(href) and is_map(link_properties) do
    rel_string = Atom.to_string(rel)
    expected_link = Map.put(link_properties, "href", href)
    assert %{^rel_string => ^expected_link} = links
    href
  end

  def has_link?(links, rel, %Regex{} = href_regex, link_properties)
      when is_atom(rel) and is_map(link_properties) do
    rel_string = Atom.to_string(rel)
    assert %{^rel_string => %{"href" => href} = link} = links
    assert link == Map.put(link_properties, "href", href)
    assert Regex.named_captures(href_regex, href)
  end

  def just_after?(iso8601, %DateTime{} = t2) when is_binary(iso8601) do
    assert {:ok, t1, 0} = DateTime.from_iso8601(iso8601)
    just_after?(t1, t2)
  end

  def just_after?(%DateTime{} = t1, %DateTime{} = t2) do
    diff = DateTime.diff(t1, t2, :microsecond)
    diff >= 0 and diff < 500_000
  end
end
