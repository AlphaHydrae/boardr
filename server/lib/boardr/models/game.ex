defmodule Boardr.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :title, :string

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(game, attrs) do
    game
      |> cast(attrs, [:title])
  end
end
