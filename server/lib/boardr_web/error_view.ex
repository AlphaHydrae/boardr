defmodule BoardrWeb.ErrorView do
  use BoardrWeb, :view

  def render(
    _,
    %{problem: %BoardrWeb.HttpProblemDetails{} = problem}
  ) do
    render_problem problem
  end

  defp render_problem(
    %BoardrWeb.HttpProblemDetails{
      title: title,
      type: type,
      status: status,
      extra_properties: extra_properties
    } = problem
  ) when is_binary(title) and is_atom(type) and is_atom(status) do
    problem
    |> Map.from_struct()
    |> omit_nil()
    |> Map.merge(%{
      status: Plug.Conn.Status.code(status),
      type: "#{Routes.api_url(BoardrWeb.Endpoint, :index)}/problems/#{String.replace(Atom.to_string(type), "_", "-")}"
    })
    |> Map.delete(:extra_properties)
    |> Map.merge(extra_properties)
  end

  def render(_, _) do
    render_problem %BoardrWeb.HttpProblemDetails{
      type: :unexpected,
      title: "An unexpected error occurred.",
      status: :internal_server_error
    }
  end
end
