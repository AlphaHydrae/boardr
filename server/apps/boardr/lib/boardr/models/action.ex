defmodule Boardr.Action do
  use Ecto.Schema

  alias Boardr.{Game,Player}
  alias Boardr.Rules.Domain

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "actions" do
    belongs_to(:game, Game)
    belongs_to(:player, Player)

    field(:position, {:array, :integer})
    field(:type, :string)

    timestamps(inserted_at: :performed_at, updated_at: false)
  end

  @doc false
  def changeset(%__MODULE__{} = action, properties) when is_map(properties) do
    action
    |> cast(properties, [:game_id, :player_id, :position, :type])
    |> validate_inclusion(:type, ["take"])
    |> validate_number(:position,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: Domain.max_board_dimension_size()
    )
    |> validate_required([:game_id, :player_id, :position, :type])
  end
end
