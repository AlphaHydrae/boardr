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

  import BoardrWeb.HalDocument, only: [put_curie: 4]

  using do
    quote do
      # Import conveniences for testing with connections.
      use Phoenix.ConnTest

      alias BoardrWeb.HalDocument
      alias BoardrWeb.Router.Helpers, as: Routes
      alias Plug.Conn

      import BoardrWeb.ConnCase, only: [api_document: 0, test_api_url: 0, test_api_url: 1]
      import HalDocument, only: [put_link: 3, put_link: 4, put_property: 3]

      # The default endpoint for testing.
      @endpoint BoardrWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Boardr.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Boardr.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def api_document() do
    api_document(%{}, true)
  end

  def api_document(properties, false) when is_map(properties) do
    HalDocument.new(properties)
  end

  def api_document(properties, true) when is_map(properties) do
    HalDocument.new(properties)
    |> put_curie(:boardr, test_api_url("/rels/{rel}"), :templated)
  end

  def test_api_url(path \\ "") do
    "http://localhost:4000/api#{path}"
  end
end
