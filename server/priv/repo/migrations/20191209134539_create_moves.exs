defmodule Boardr.Repo.Migrations.CreateMoves do
  use Ecto.Migration

  def change do
    execute ~s/CREATE TYPE move_types AS ENUM ('take');/, ~s/DROP TYPE move_types;/

    create table(:moves, primary_key: false) do
      add :data, :jsonb, null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :type, :move_types, null: false
      timestamps inserted_at: :played_at, type: :utc_datetime, updated_at: false
    end
  end
end
