defmodule BoardrWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BoardrWeb.ConnCase, async: true`, although
  this option is not recommendded for other databases.
  """

  use ExUnit.CaseTemplate

  alias BoardrWeb.HalDocument
  alias Plug.Conn

  import Asserter.Assertions
  import BoardrWeb.HalDocument, only: [put_curie: 4]
  import Phoenix.ConnTest, only: [post: 3]
  import Plug.Conn, only: [put_req_header: 3]

  @endpoint BoardrWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with connections.
      use Phoenix.ConnTest

      alias Boardr.Repo
      alias BoardrWeb.HalDocument
      alias BoardrWeb.Router.Helpers, as: Routes
      alias Plug.Conn

      import BoardrWeb.ConnCase,
        only: [
          api_document: 0,
          assert_api_map: 1,
          assert_hal_link: 2,
          assert_hal_link: 3,
          assert_hal_link: 4,
          post_json: 3,
          test_api_url: 0,
          test_api_url: 1,
          test_api_url_regex: 1,
          verify_jwt_token!: 1
        ]

      import BoardrWeb.QueryCounter, only: [count_queries: 1, counted_queries: 1]
      import HalDocument, only: [put_link: 3, put_link: 4, put_property: 3]

      # The default endpoint for testing.
      @endpoint BoardrWeb.Endpoint
    end
  end

  setup_all do
    %{
      test_start: DateTime.utc_now()
    }
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Boardr.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Boardr.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def api_document(properties \\ %{}, include_default_curie \\ true)

  def api_document(properties, false) when is_map(properties) do
    properties
  end

  def api_document(properties, true) when is_map(properties) do
    properties
    |> put_curie(:boardr, test_api_url("/rels/{rel}"), :templated)
  end

  def assert_api_map(value) when is_map(value) do
    assert_map(value)
    # Transform result keys into underscored atoms.
    |> on_assert_key_result(fn result, key, value, _opts ->
      cond do
        is_map(result) ->
          Map.put(result, convert_asserter_result_key(key), value)
      end
    end)
    # Retrieve values of transformed identical keys.
    |> on_get_identical_key_value(fn %Asserter{result: result, subject: subject}, key, identical_key, _opts ->
      Map.get(result, convert_asserter_result_key(identical_key), Map.get(subject, key))
    end)
  end

  def assert_hal_link(%Asserter{subject: subject} = asserter, href, link_properties \\ %{}, opts \\ []) when is_map(subject) and is_map(link_properties) and is_list(opts) do
    chain = asserter
    |> assert_map()
    |> assert_key("href", href, opts)

    Enum.reduce(link_properties, chain, fn {key, value}, acc -> acc |> assert_key(key, value, opts) end)
  end

  def post_json(%Conn{} = conn, path, value) when is_binary(path) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(path, Jason.encode!(value))
  end

  def test_api_url(path \\ "") do
    "http://localhost:4000/api#{path}"
  end

  def test_api_url_regex(parts) when is_list(parts) do
    ~r/#{
      ([~r/^/, test_api_url()] ++ parts ++ [~r/$/])
      |> Enum.map(&test_api_url_regex_part/1)
      |> Enum.join("")
    }/
  end

  def verify_jwt_token!(token) when is_binary(token) do
    jwt_private_key = Application.get_env(:boardr, BoardrWeb.Endpoint)[:jwt_private_key]
    signer = Joken.Signer.create("RS512", %{"pem" => jwt_private_key})
    {:ok, claims} = Joken.verify(token, signer)
    claims
  end

  defp convert_asserter_result_key(key) when is_binary(key) do
    key |> Inflex.underscore() |> String.to_atom()
  end

  defp test_api_url_regex_part(part) when is_binary(part) do
    Regex.escape(part)
  end

  defp test_api_url_regex_part(%Regex{} = part) do
    assert Regex.opts(part) == ""
    Regex.source(part)
  end
end
