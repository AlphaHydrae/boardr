defmodule Boardr.Auth do
  @moduledoc """
  The Auth context.
  """

  alias Boardr.Auth.{Identity,User}
  alias Boardr.Repo
  alias Ecto.{Changeset,Multi}

  import Ecto.Query, warn: false

  def ensure_identity(%{"email" => email, "provider" => "local"}, _) when is_binary(email) do
    # FIXME: add password
    with {:ok, identity} <- upsert_identity(%{
           email: email,
           email_verified: false,
           provider: "local",
           provider_id: String.downcase(email)
         }) do
      {:ok, Repo.preload(identity, :user)}
    else _ ->
      {:auth_error, :auth_failed}
    end
  end

  def ensure_identity(%{"provider" => "google"}, token) when is_binary(token) do

    url = :uri_string.parse "https://oauth2.googleapis.com/tokeninfo"
    query_params = :uri_string.compose_query [{"id_token", token}]
    url = :uri_string.recompose Map.put(url, :query, query_params)

    # FIXME: check "aud" claim is correct google client ID
    # FIXME: check supplied provider ID is the same google account ID
    now = DateTime.utc_now()
    with {:ok, %HTTPoison.Response{body: json, status_code: 200}} <- HTTPoison.get(url),
         {:ok, body} <- Jason.decode(json),
         {:ok, identity} = upsert_identity(
           %{
             email: body["email"],
             email_verified: body["email_verified"],
             email_verified_at: (if body["email_verified"], do: now, else: nil),
             provider: "google",
             provider_id: body["sub"]
           },
           now
         ) do
      {:ok, Repo.preload(identity, :user)}
    else _ ->
      {:auth_error, :auth_failed}
    end
  end

  def register_user(%Identity{} = identity, user_properties) when is_map(user_properties) do
    case create_and_link_user_to_identity(identity, user_properties) do
      {:ok, %{identity: identity}} -> {:ok, identity}
      {:error, :user, %Changeset{} = validation_errors, _} -> {:validation_error, validation_errors}
      true -> {:error, :user_registration_failed}
    end
  end

  defp create_and_link_user_to_identity(%Identity{} = identity, user_properties) when is_map(user_properties) do
    Multi.new
    |> Multi.insert(:user, User.changeset(%User{}, user_properties), returning: [:id])
    |> Multi.run(:identity, fn repo, %{user: user} ->
      Identity.changeset(identity, %{})
      |> Changeset.put_assoc(:user, user)
      |> repo.update
    end)
    |> Repo.transaction
  end

  defp upsert_identity(identity_properties) when is_map(identity_properties) do
    upsert_identity identity_properties, DateTime.utc_now()
  end

  defp upsert_identity(identity_properties, now) when is_map(identity_properties) do
    %Identity{}
    |> Identity.changeset(Map.merge(identity_properties, %{
      last_authenticated_at: now,
      last_seen_at: now
    }))
    |> Repo.insert(
      conflict_target: [:provider, :provider_id],
      on_conflict: [
        set: Keyword.merge(Map.to_list(identity_properties), [
          last_authenticated_at: now,
          last_seen_at: now,
          updated_at: now
        ])
      ],
      returning: [:created_at, :id, :updated_at]
    )
  end
end
