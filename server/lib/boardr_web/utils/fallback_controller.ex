defmodule BoardrWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:auth_error, error}) do
    render_problem conn, %BoardrWeb.HttpProblemDetails{
      type: error,
      title: "Authentication has failed.",
      status: :unauthorized
    }
  end

  def call(conn, {:client_error, %BoardrWeb.HttpProblemDetails{} = problem}) do
    render_problem conn, problem
  end

  defp render_problem(conn, %BoardrWeb.HttpProblemDetails{} = problem) do
    conn
    |> put_status(problem.status)
    |> put_resp_content_type("application/problem+json")
    |> merge_assigns(problem: problem)
    |> put_view(BoardrWeb.ErrorView)
    |> render("error.json")
  end
end
