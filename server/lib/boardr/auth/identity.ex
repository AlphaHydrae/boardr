defmodule Boardr.Auth.Identity do
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "identities" do
    belongs_to :user, Boardr.Auth.User
    field :last_authenticated_at, :utc_datetime
    field :last_seen_at, :utc_datetime

    timestamps(inserted_at: :created_at, updated_at: false)
  end

  @doc false
  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:last_authenticated_at, :last_seen_at, :user_id])
    |> validate_required([:last_authenticated_at, :last_seen_at])
  end
end
