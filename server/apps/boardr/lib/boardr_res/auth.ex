defmodule BoardrRes.Auth do
  use Rop

  alias Boardr.Auth.Token

  import BoardrRes

  def authorize(ctx, required_scopes \\ nil)

  def authorize(context() = ctx, nil) do
    authorize(ctx, [])
  end

  def authorize(context() = ctx, required_scope) when is_atom(required_scope) do
    authorize(ctx, [required_scope])
  end

  def authorize(context() = ctx, required_scopes) when is_list(required_scopes) do
    auth_header_required = length(required_scopes) >= 1

    ctx
    |> get_bearer_token(auth_header_required)
    >>> verify_token(auth_header_required)
    >>> verify_scopes(required_scopes)
  end

  defp get_bearer_token(context() = ctx, false) do
    {:ok, ctx}
  end

  defp get_bearer_token(context(options: options(authorization_header: [])), true) do
    {:error, :auth_header_missing}
  end

  defp get_bearer_token(context(options: options(authorization_header: header_values)), true) when length(header_values) >= 2 do
    {:error, :auth_header_duplicated}
  end

  defp get_bearer_token(context(options: options(authorization_header: [header_value])) = ctx, true) when is_binary(header_value) do
    case String.split(header_value, " ", parts: 2) do
      [ _, token ] -> assign(ctx, :token, token)
      _ -> {:error, :auth_header_malformed}
    end
  end

  defp get_missing_scopes(%MapSet{} = scopes, %MapSet{} = required_scopes) do
    Enum.reject(required_scopes, fn required_scope -> has_scope?(scopes, Atom.to_string(required_scope)) end)
  end

  defp has_scope?(%MapSet{} = token_scopes, scope) when is_binary(scope) do
    Enum.any? token_scopes, fn token_scope -> token_scope == scope or String.starts_with?(scope, "#{token_scope}:") end
  end

  defp verify_scopes(context() = ctx, []) do
    {:ok, ctx}
  end

  defp verify_scopes(context(assigns: %{claims: %{"scope" => scope, "sub" => sub}}) = ctx, required_scopes) when is_binary(scope) and is_binary(sub) and is_list(required_scopes) do
    case get_missing_scopes(MapSet.new(String.split(scope, " ")), MapSet.new(required_scopes)) do
      [] -> {:ok, ctx}
      missing_scopes -> {:error, {:auth_missing_scopes, missing_scopes}}
    end
  end

  defp verify_scopes(context(assigns: %{claims: %{"sub" => subject}}), _) when is_binary(subject) do
    {:error, :auth_jwt_scope_missing}
  end

  defp verify_scopes(context(assigns: %{claims: %{}}), _) do
    {:error, :auth_jwt_subject_missing}
  end

  defp verify_token(context() = ctx, false) do
    {:ok, ctx}
  end

  defp verify_token(context(assigns: %{token: token}) = ctx, true) when is_binary(token) do
    case Token.verify(token) do
      {:ok, claims} -> assign(ctx, :claims, claims)
      {:error, err} -> {:error, err}
    end
  end
end
