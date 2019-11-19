defmodule Boardr.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :number_of_players, :integer
    field :rules, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
      |> cast(attrs, [:number_of_players, :rules])
      |> validate_required([:number_of_players, :rules])
  end
end
