defmodule Boardr.Player do
  use Ecto.Schema

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "players" do
    belongs_to :game, Boardr.Game
    belongs_to :user, Boardr.Auth.User

    field :number, :integer

    timestamps inserted_at: :created_at, updated_at: false
  end

  @doc false
  def changeset(game, attrs) do
    game
      |> cast(attrs, [:number])
  end
end
