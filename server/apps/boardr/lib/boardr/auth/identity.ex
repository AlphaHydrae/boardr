defmodule Boardr.Auth.Identity do
  use Ecto.Schema

  alias Boardr.Auth.User

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "identities" do
    belongs_to :user, User

    field :email, :string
    field :email_verified, :boolean
    field :email_verified_at, :utc_datetime_usec
    field :last_authenticated_at, :utc_datetime_usec
    # TODO: implement last seen at
    field :last_seen_at, :utc_datetime_usec
    field :provider, :string
    field :provider_id, :string
    field :token, :string, virtual: true

    timestamps inserted_at: :created_at
  end

  @doc false
  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [
      :email,
      :email_verified,
      :email_verified_at,
      :last_authenticated_at,
      :last_seen_at,
      :provider,
      :provider_id,
      :user_id
    ])
    |> validate_required([
      :email_verified,
      :last_authenticated_at,
      :last_seen_at,
      :provider,
      :provider_id
    ])
    |> unique_constraint(:provider_id, name: :identities_provider_and_id_unique)
  end
end
