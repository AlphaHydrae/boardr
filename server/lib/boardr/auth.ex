defmodule Boardr.Auth do
  @moduledoc """
  The Auth context.
  """

  import Ecto.Query, warn: false
  alias Boardr.Repo

  alias Boardr.Auth.{Identity,User}

  def ensure_identity(provider, token) when is_binary(provider) do

    url = :uri_string.parse "https://oauth2.googleapis.com/tokeninfo"
    query_params = :uri_string.compose_query [{"id_token", token}]
    url = :uri_string.recompose Map.put(url, :query, query_params)
    # FIXME: check "aud" claim is correct google client ID
    # FIXME: check supplied provider ID is the same google account ID

    with {:ok, %HTTPoison.Response{body: json, status_code: 200}} <- HTTPoison.get(url),
         {:ok, body} <- Jason.decode(json),
         now = DateTime.utc_now(),
         changeset = Identity.changeset(%Identity{}, %{
           email: body["email"],
           email_verified: body["email_verified"],
           email_verified_at: (if body["email_verified"], do: now, else: nil),
           last_authenticated_at: now,
           last_seen_at: now,
           provider: provider,
           provider_id: body["sub"]
         }),
         {:ok, identity} <- Repo.insert(
           changeset,
           conflict_target: [:provider, :provider_id],
           on_conflict: [set: [
             email: body["email"],
             email_verified: body["email_verified"],
             email_verified_at: (if body["email_verified"], do: now, else: nil),
             last_authenticated_at: now,
             last_seen_at: now,
             updated_at: now
           ]],
           returning: [:created_at, :id, :updated_at]
         ) do
      {:ok, Repo.preload(identity, :user)}
    else _ ->
      {:auth_error, :auth_failed}
    end
  end

  def register_user(properties) when is_map(properties) do
    changeset = User.changeset %User{}, properties
    with {:ok, user} <- Repo.insert(changeset, returning: [:id]) do
      {:ok, user}
    else _ ->
      {:error, :user_not_created}
    end
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
