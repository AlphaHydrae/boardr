defmodule Boardr.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "games" do
    field :title, :string
    field :data, :map

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(game, attrs) do
    game
      |> cast(attrs, [:title])
  end
end
