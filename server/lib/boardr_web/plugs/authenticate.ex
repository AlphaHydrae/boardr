defmodule BoardrWeb.Authenticate do
  use BoardrWeb, :plug

  alias Boardr.Auth.Token

  def init(scopes) when is_list(scopes) do
    MapSet.new Enum.map(scopes, &Atom.to_string/1)
  end

  def call(%Conn{} = conn, %MapSet{} = scopes) do
    with {:ok, token} <- get_authorization_token(conn),
         {:ok, claims} <- Token.verify(token),
         {:ok, _} <- verify_scopes(claims, scopes) do
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
            type: :'auth-token-invalid'
          }))
      end
    end
  end

  def get_authorization_token(%Conn{} = conn) do
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

  defp authentication_problem_details(
    %HttpProblemDetails{detail: detail, type: type} = details
  ) when is_binary(detail) and is_atom(type) do
    %HttpProblemDetails{
      details |
      status: :unauthorized,
      title: "You are not authorized to access this resource."
    }
  end

  defp authorization_problem_details(
    %HttpProblemDetails{detail: detail, type: type} = details
  ) when is_binary(detail) and is_atom(type) do
    %HttpProblemDetails{
      details |
      status: :forbidden,
      title: "You do not have sufficient permissions to perform this request.",
    }
  end

  defp get_bearer_token(header_value) when is_binary(header_value) do
    with [ _, token ] <- String.split(header_value, " ", parts: 2) do
      {:ok, token}
    else _ ->
      {
        :problem,
        authentication_problem_details(%HttpProblemDetails{
          detail: ~s(The Authorization header is invalid. It must be contain the string "Bearer" followed by exactly one space and a valid Bearer token.) ,
          type: :'auth-header-malformed'
        })
      }
    end
  end

  defp verify_scopes(%{"scope" => token_scope, "sub" => subject}, %MapSet{} = scopes) when is_binary(subject) and is_binary(token_scope) do
    token_scopes = String.split token_scope, " "
    missing_scopes = MapSet.difference scopes, MapSet.new(token_scopes)
    if MapSet.size(missing_scopes) <= 0 do
      {:ok, scopes}
    else
      {
        :problem,
        authorization_problem_details(%HttpProblemDetails{
          detail: ~s(The Bearer token sent in the Authorization header is missing the following required scopes: #{Enum.join(Enum.map(missing_scopes, fn scope -> ~s("#{scope}") end), ", ")}.),
          type: :'auth-forbidden'
        })
      }
    end
  end

  defp verify_scopes(%{"sub" => subject}, _) when is_binary(subject) do
    {
      :problem,
      authorization_problem_details(%HttpProblemDetails{
        detail: ~s(The Bearer token sent in the Authorization header has no scope.),
        type: :'auth-token-scope-missing'
      })
    }
  end

  defp verify_scopes(_, _) do
    {
      :problem,
      authorization_problem_details(%HttpProblemDetails{
        detail: ~s(The Bearer token sent in the Authorization header has no subject.),
        type: :'auth-token-subject-missing'
      })
    }
  end
end
