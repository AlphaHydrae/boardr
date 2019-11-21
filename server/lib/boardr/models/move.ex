defmodule Boardr.Move do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "moves" do
    field :game_id, Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(move, attrs) do
    move
    |> cast(attrs, [:game_id])
    |> validate_required([:game_id])
  end
end
