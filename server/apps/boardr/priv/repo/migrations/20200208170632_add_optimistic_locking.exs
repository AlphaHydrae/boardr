defmodule Boardr.Repo.Migrations.AddOptimisticLocking do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :lock_version, :integer, default: 0, null: false
    end
  end
end
