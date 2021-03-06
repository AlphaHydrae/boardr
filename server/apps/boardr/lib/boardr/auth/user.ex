defmodule Boardr.Auth.User do
  use Ecto.Schema

  alias Boardr.Auth.Identity

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "users" do
    has_many :identities, Identity

    # FIXME: limit length
    field :name, :string
    field :token, :string, virtual: true

    timestamps inserted_at: :created_at
  end

  @doc false
  def changeset(%__MODULE__{} = user, attrs) when is_map(attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :users_name_unique)
  end
end
