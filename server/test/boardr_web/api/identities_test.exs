defmodule BoardrWeb.IdentitiesTest do
  use BoardrWeb.ConnCase, async: true

  alias Boardr.Auth.Identity

  import BoardrWeb.Assertions
  import MapChecker

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

      %{result: %{id: identity_id} = expected_identity} = MapChecker.new(body)
        |> check_hal_property("_links", fn links ->
          MapChecker.new(links)
          |> check_hal_property_missing("boardr:user", nil, :user_id)
          |> check_hal_property("self", fn self ->
            MapChecker.new(self)
            |> check_hal_property("href", test_api_url_regex(["/identities/", ~r/(?<id>[\w-]+)/]), merge: true)
          end, merge: true)
          |> ignore_hal_properties(["collection"])
        end, merge: true)
        |> check_hal_properties(@valid_properties, %{"email" => :email, "provider" => :provider})
        |> check_hal_property("createdAt", &(&1 |> just_after(test_start)), :created_at)
        |> check_hal_property("emailVerified", false, :email_verified)
        |> check_hal_property_missing("emailVerifiedAt", nil, :email_verified_at)
        |> check_hal_property("lastAuthenticatedAt", &(&1 |> just_after(test_start)), :last_authenticated_at)
        |> check_hal_property("lastSeenAt", body["lastAuthenticatedAt"], from: :last_authenticated_at, into: :last_seen_at)
        |> check_hal_property("providerId", body["email"], from: :email, into: :provider_id)
        |> check_hal_property("updatedAt", body["createdAt"], from: :created_at, into: :updated_at)
        |> ignore_hal_properties(["_embedded"])

      # Check the expected number of database queries were made.
      assert query_counter |> counted_queries == %{insert: 1}

      assert_in_db Identity, identity_id, expected_identity
    end
  end

  def parse_hal_link(link, href, link_properties \\ %{})

  def parse_hal_link(link, %Regex{} = href, link_properties)
      when is_map(link) and is_map(link_properties) do
    actual_href = link["href"]
    captures = Regex.named_captures(href, actual_href)

    if !is_nil(captures) and Map.put(link_properties, "href", actual_href) == link do
      Map.put(link, "href", captures)
    else
      false
    end
  end

  def parse_hal_link(link, href, link_properties)
      when is_map(link) and is_binary(href) and is_map(link_properties) do
    if Map.put(link_properties, "href", href) == link do
      link
    else
      false
    end
  end

  def just_after(iso8601, %DateTime{} = t2) when is_binary(iso8601) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, t1, 0} -> just_after(t1, t2)
      {:ok, _, _} -> {:nok, [message: "is not UTC", expected_just_after: t2]}
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
