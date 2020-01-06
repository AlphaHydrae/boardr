defmodule BoardrApi.HttpProblemDetailsHelpers do
  alias BoardrApi.{ErrorView,HttpProblemDetails}

  import Phoenix.Controller, only: [put_view: 2, render: 2]
  import Plug.Conn, only: [assign: 3, put_resp_content_type: 2, put_status: 2]

  def render_problem(conn, %HttpProblemDetails{} = problem) do
    conn
    |> put_status(problem.status || 500)
    |> put_resp_content_type("application/problem+json")
    |> assign(:problem, problem)
    |> put_view(ErrorView)
    |> render("error.json")
  end
end
