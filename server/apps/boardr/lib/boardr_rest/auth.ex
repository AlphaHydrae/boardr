defmodule BoardrRest.Auth do
  alias Boardr.Auth.Token

  import BoardrRest

  @type auth_error_details ::
          {:auth_error, :jwt_scope_insufficient, list(binary)}
          | {:auth_error, :jwt_scope_missing}
          | {:auth_error, :jwt_subject_invalid}
          | {:auth_error, :jwt_subject_missing}
          | {:auth_error, :missing_authorization}

  @spec authorize(BoardrRest.operation, :identity | :user, atom | list(atom)) ::
          {:ok, BoardrRest.authorization} | {:error, auth_error_details}

  def authorize(operation() = op, subject_type, required_scope)
      when is_atom(subject_type) and is_atom(required_scope) do
    authorize(op, subject_type, [required_scope])
  end

  def authorize(operation(authorization: nil), subject_type, [_ | _])
      when is_atom(subject_type) do
    {:error, {:auth_error, :missing_authorization}}
  end

  def authorize(
        operation(authorization: {:bearer_token, token}),
        subject_type,
        [_ | _] = required_scopes
      )
      when is_atom(subject_type) do
    with {:ok, claims} <- Token.verify(token),
         {:ok, scopes} <- verify_scopes(claims, required_scopes) do
      create_authorization(subject_type, claims, scopes)
    end
  end

  defp create_authorization(:identity, %{"sub" => subject}, scopes) when is_list(scopes) do
    case subject do
      "i:" <> identity_id -> {:ok, {:identity, identity_id, scopes}}
      _ -> {:error, {:auth_error, :jwt_subject_invalid}}
    end
  end

  defp create_authorization(:user, %{"sub" => subject}, scopes) when is_list(scopes) do
    case subject do
      "u:" <> user_id -> {:ok, {:user, user_id, scopes}}
      _ -> {:error, {:auth_error, :jwt_subject_invalid}}
    end
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

  defp verify_scopes(%{"scope" => scope, "sub" => sub}, required_scopes)
       when is_binary(scope) and is_binary(sub) and is_list(required_scopes) do
    scopes = String.split(scope, " ")

    case get_missing_scopes(MapSet.new(scopes), MapSet.new(required_scopes)) do
      [] -> {:ok, scopes}
      missing_scopes -> {:error, {:auth_error, :jwt_scope_insufficient, missing_scopes}}
    end
  end

  defp verify_scopes(%{"sub" => subject}, _) when is_binary(subject) do
    {:error, {:auth_error, :jwt_scope_missing}}
  end

  defp verify_scopes(%{}, _) do
    {:error, {:auth_error, :jwt_subject_missing}}
  end
end
