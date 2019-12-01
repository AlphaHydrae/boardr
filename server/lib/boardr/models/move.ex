defmodule Boardr.Move do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "moves" do
    field :data, EctoJsonb

    belongs_to :game, Boardr.Game

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(move, attrs) do
    move
    |> cast(attrs, [:data, :game_id])
    |> validate_required([:game_id])
  end
end
