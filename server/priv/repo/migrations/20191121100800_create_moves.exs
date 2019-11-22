defmodule Boardr.Repo.Migrations.CreateMoves do
  use Ecto.Migration

  def change do
    create table(:moves, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :data, :jsonb, null: false

      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

  end
end
