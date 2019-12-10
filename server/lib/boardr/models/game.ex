defmodule Boardr.Game do
  use Ecto.Schema

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "games" do
    belongs_to :creator, Boardr.Auth.User
    has_many :actions, Boardr.Action
    has_many :players, Boardr.Player
    many_to_many :winners, Boardr.Player, join_through: "winners"

    field :state, :string
    field :title, :string
    field :data, EctoJsonb

    timestamps inserted_at: :created_at
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:state, :title])
    |> validate_inclusion(:state, ["waiting_for_players", "playing", "draw", "win"])
  end
end
