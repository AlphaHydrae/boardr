defmodule BoardrRest.Auth do
  use Rop

  alias Boardr.Auth.Token

  import BoardrRest

  def authorize(op, required_scopes \\ nil)

  def authorize(operation() = op, nil) do
    authorize(op, [])
  end

  def authorize(operation() = op, required_scope) when is_atom(required_scope) do
    authorize(op, [required_scope])
  end

  def authorize(operation() = op, required_scopes) when is_list(required_scopes) do
    auth_header_required = length(required_scopes) >= 1

    op
    |> get_bearer_token(auth_header_required) >>>
      verify_token(auth_header_required) >>>
      verify_scopes(required_scopes)
  end

  def get_bearer_token(operation() = op, false) do
    {:ok, op}
  end

  def get_bearer_token(
        operation(options: %{authorization: authorization} = options) = op,
        true
      )
      when is_binary(authorization) do
    case String.split(authorization, " ", parts: 2) do
      [_, token] ->
        {
          :ok,
          operation(op, options: Map.put(options, :authorization_token, token))
        }

      _ ->
        {:error, :auth_malformed}
    end
  end

  def get_bearer_token(operation(options: %{authorization: _authorization}), true) do
    {:error, :auth_type_mismatch}
  end

  def get_bearer_token(operation(), true) do
    {:error, :auth_missing}
  end

  defp get_missing_scopes(%MapSet{} = scopes, %MapSet{} = required_scopes) do
    Enum.reject(required_scopes, fn required_scope ->
      has_scope?(scopes, Atom.to_string(required_scope))
    end)
  end

  defp has_scope?(%MapSet{} = token_scopes, scope) when is_binary(scope) do
    Enum.any?(token_scopes, fn token_scope ->
      token_scope == scope or String.starts_with?(scope, "#{token_scope}:")
    end)
  end

  defp verify_scopes(operation() = op, []) do
    {:ok, op}
  end

  defp verify_scopes(
         operation(options: %{authorization_claims: %{"scope" => scope, "sub" => sub}}) = op,
         required_scopes
       )
       when is_binary(scope) and is_binary(sub) and is_list(required_scopes) do
    case get_missing_scopes(MapSet.new(String.split(scope, " ")), MapSet.new(required_scopes)) do
      [] -> {:ok, op}
      missing_scopes -> {:error, {:auth_missing_scopes, missing_scopes}}
    end
  end

  defp verify_scopes(operation(options: %{authorization_claims: %{"sub" => subject}}), _)
       when is_binary(subject) do
    {:error, :auth_jwt_scope_missing}
  end

  defp verify_scopes(operation(options: %{authorization_claims: %{}}), _) do
    {:error, :auth_jwt_subject_missing}
  end

  defp verify_token(operation() = op, false) do
    {:ok, op}
  end

  defp verify_token(operation(options: %{authorization_token: token} = options) = op, true)
       when is_binary(token) do
    case Token.verify(token) do
      {:ok, claims} ->
        {
          :ok,
          operation(op, options: Map.put(options, :authorization_claims, claims))
        }

      {:error, err} ->
        {:error, err}
    end
  end
end
