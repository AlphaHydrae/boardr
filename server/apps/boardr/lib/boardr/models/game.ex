defmodule Boardr.Game do
  use Ecto.Schema

  alias Boardr.{Action,Player}
  alias Boardr.Auth.User

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "games" do
    belongs_to :creator, User
    has_many :actions, Action
    has_many :players, Player
    many_to_many :winners, Player, join_through: "winners", on_replace: :mark_as_invalid

    field :lock_version, :integer
    field :rules, :string
    field :settings, EctoJsonb
    field :state, :string
    field :title, :string

    timestamps inserted_at: :created_at
  end

  @doc false
  def changeset(%__MODULE__{} = game, attrs) when is_map(attrs) do
    game
    |> cast(attrs, [:state, :title])
    |> validate_inclusion(:state, ["waiting_for_players", "playing", "draw", "win"])
    |> optimistic_lock(:lock_version)
  end
end
