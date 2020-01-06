defmodule BoardrApi.ErrorView do
  use BoardrApi, :view

  def render(
    _,
    %{problem: %BoardrApi.HttpProblemDetails{} = problem}
  ) do
    render_problem problem
  end

  def render(_, _) do
    render_problem %BoardrApi.HttpProblemDetails{
      type: :unexpected,
      title: "An unexpected error occurred.",
      status: :internal_server_error
    }
  end

  defp render_problem(
    %BoardrApi.HttpProblemDetails{
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
      type: "#{Routes.api_root_url(BoardrApi.Endpoint, :index)}/problems/#{String.replace(Atom.to_string(type), "_", "-")}"
    })
    |> Map.delete(:extra_properties)
    |> Map.merge(extra_properties)
  end
end
