defmodule BoardrWeb.FallbackController do
  use Phoenix.Controller
  import BoardrWeb.ControllerHelpers

  def call(conn, {:auth_error, error}) do
    render_problem conn, %BoardrWeb.HttpProblemDetails{
      type: error,
      title: "Authentication has failed.",
      status: :unauthorized
    }
  end

  def call(conn, {:error, %BoardrWeb.HttpProblemDetails{} = problem}) do
    conn
    |> render_problem(problem)
  end
end
