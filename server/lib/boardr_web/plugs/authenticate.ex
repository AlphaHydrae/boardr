defmodule BoardrWeb.Authenticate do
  use BoardrWeb, :plug

  alias BoardrWeb.Auth

  def init(scopes) do
    scopes
  end

  def call(%Conn{} = conn, scopes) do
    with {:ok, token} <- get_authorization_token(conn),
         {:ok, claims} <- Auth.verify(token) do
      conn
      |> assign(:auth, claims)
    else result ->
      case result do
        {:problem, problem} ->
          conn
          |> halt()
          |> render_problem(problem)
        _ ->
          conn
          |> halt()
          |> render_problem(authentication_problem_details(%HttpProblemDetails{
            detail: "The Bearer token sent in the Authorization header is invalid or has expired.",
            type: :'auth-failed'
          }))
      end
    end
  end

  def get_authorization_token(conn) do
    header_values = get_req_header conn, "authorization"
    header_values_length = length header_values
    cond do
      header_values_length <= 0 -> {
        :problem,
        authentication_problem_details(%HttpProblemDetails{
          detail: ~s(This request requires user authentication. Send an Authorization header containing a valid Bearer token.),
          type: :'auth-header-missing'
        })
      }
      header_values_length >= 2 -> {
        :problem,
        authentication_problem_details(%HttpProblemDetails{
          detail: ~s(The Authorization header contains multiple values. One and only one Bearer token must be sent.),
          type: :'auth-header-duplicated'
        })
      }
      true -> get_bearer_token(List.first(header_values))
    end
  end

  defp get_bearer_token(header_value) when is_binary(header_value) do
    if [ _, token ] = String.split header_value, " ", parts: 2 do
      {:ok, token}
    else
      {
        :problem,
        authentication_problem_details(%HttpProblemDetails{
          detail: ~s(The Authorization header is invalid. It must be contain the string "Bearer" followed by exactly one space and a valid Bearer token.) ,
          type: :'auth-header-malformed'
        })
      }
    end
  end

  defp authentication_problem_details(
    %HttpProblemDetails{detail: detail, type: type} = details
  ) when is_binary(detail) and is_atom(type) do
    %HttpProblemDetails{
      details |
      status: :unauthorized,
      title: "You are not authorized to access this resource."
    }
  end
end
