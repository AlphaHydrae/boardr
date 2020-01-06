defmodule Boardr.Player do
  use Ecto.Schema

  alias Boardr.Auth.User
  alias Boardr.{Game}

  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "players" do
    belongs_to :game, Game
    belongs_to :user, User

    field :number, :integer
    field :settings, EctoJsonb

    timestamps inserted_at: :created_at, updated_at: false
  end

  @doc false
  def changeset(%__MODULE__{} = player, attrs) when is_map(attrs) do
    player
    |> cast(attrs, [:number])
    |> unique_constraint(:number, name: :players_game_id_and_number_unique)
    |> unique_constraint(:user_id, name: :players_game_id_and_user_id_unique)
  end
end
