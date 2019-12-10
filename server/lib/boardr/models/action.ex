defmodule Boardr.Action do
  use Ecto.Schema

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "actions" do
    belongs_to :game, Boardr.Game
    belongs_to :player, Boardr.Player

    field :data, EctoJsonb
    field :type, :string

    timestamps inserted_at: :performed_at, updated_at: false
  end

  @doc false
  def changeset(%__MODULE__{} = action, properties) when is_map(properties) do
    action
    |> cast(properties, [:data, :game_id, :player_id, :type])
    |> validate_inclusion(:type, ["take"])
    |> validate_required([:data, :game_id, :player_id, :type])
  end
end
