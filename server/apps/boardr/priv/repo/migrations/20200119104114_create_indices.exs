defmodule Boardr.Repo.Migrations.CreateIndices do
  use Ecto.Migration

  def change do
    create index(:actions, [:game_id])
    create index(:games, [:state])
    create index(:players, [:game_id])
    create index(:players, [:number])
  end
end
