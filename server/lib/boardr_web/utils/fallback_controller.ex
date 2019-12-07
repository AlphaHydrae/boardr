defmodule BoardrWeb.FallbackController do
  use Phoenix.Controller

  alias BoardrWeb.HttpProblemDetails

  import BoardrWeb.HttpProblemDetailsHelpers

  def call(conn, {:auth_error, error}) do
    render_problem conn, %HttpProblemDetails{
      type: error,
      title: "Authentication has failed.",
      status: :unauthorized
    }
  end

  def call(conn, {:problem, %HttpProblemDetails{} = problem}) do
    conn
    |> render_problem(problem)
  end
end
