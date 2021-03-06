defmodule BoardrApi.ConnCase do
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
  by setting `use BoardrApi.ConnCase, async: true`, although
  this option is not recommendded for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Asserter
      # Import conveniences for testing with connections.
      use Phoenix.ConnTest

      alias Boardr.{Fixtures,Repo}
      alias BoardrApi.Router.Helpers, as: Routes
      alias Plug.Conn

      import BoardrApi.Assertions
      import BoardrApi.ConnCaseHelpers,
        only: [
          clean_database: 0,
          clean_database: 1,
          generate_token!: 1,
          just_after: 2,
          just_after: 3,
          post_json: 3,
          test_api_url: 0,
          test_api_url: 1,
          test_api_url_regex: 1,
          verify_jwt_token!: 1
        ]
      import BoardrApi.DomainAssertions

      import QueryCounter, only: [count_queries: 1, counted_queries: 0]

      # The default endpoint for testing.
      @endpoint BoardrApi.Endpoint
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
end
