defmodule Boardr.Repo.Migrations.CreateActions do
  use Ecto.Migration

  def change do
    execute ~s/CREATE TYPE action_types AS ENUM ('take');/, ~s/DROP TYPE action_types;/

    create table(:actions, primary_key: false) do
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :position, :integer, null: false
      add :type, :action_types, null: false
      timestamps inserted_at: :performed_at, type: :utc_datetime_usec, updated_at: false
    end
  end
end
