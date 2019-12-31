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

      %{result: %{id: identity_id} = expected_identity} = assert_body(body)
        |> assert_key("_links", fn links ->
          assert_map(links)
          |> assert_key_absent("boardr:user", nil, into: :user_id)
          |> assert_key("collection", fn collection ->
            assert_map(collection)
            |> assert_key("href", test_api_url("/identities"), into: false)
          end)
          |> assert_key("self", fn self ->
            assert_map(self)
            |> assert_key("href", test_api_url_regex(["/identities/", ~r/(?<id>[\w-]+)/]))
          end)
        end, merge: true)
        |> assert_keys(@valid_properties)
        |> assert_key("createdAt", &(&1 |> just_after(test_start)), value: true)
        |> assert_key("emailVerified", false)
        |> assert_key_absent("emailVerifiedAt", nil)
        |> assert_key("lastAuthenticatedAt", &(&1 |> just_after(test_start)), value: true)
        |> assert_key("lastSeenAt", body["lastAuthenticatedAt"], from: :last_authenticated_at)
        |> assert_key("providerId", body["email"], from: :email)
        |> assert_key("updatedAt", body["createdAt"], from: :created_at)
        |> ignore_keys(["_embedded"])

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
